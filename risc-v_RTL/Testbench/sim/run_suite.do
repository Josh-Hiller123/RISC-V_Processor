
set ::RV32UI_BUILD risc-v_RTL/Testbench/programs/rv32ui/build
set ::RV32UI_BOUND "500 ms"   ;# 50,000 cycles @ 10us clock; bounds divergent hangs

proc rv32ui_compile {} {
    catch {quit -sim}   ;# clear any sim currently loaded so the recompile can't collide
    vlib work
    vmap work work
    vlog -sv +define+RVFI -f risc-v_RTL/Testbench/sim/filelist.f
    vopt +acc tb_top -o tb_top_opt
}

proc rv32ui_run {{tests {}}} {
    set build $::RV32UI_BUILD
    if {[llength $tests] == 0} {
        foreach h [lsort [glob -nocomplain $build/*.hex]] {
            lappend tests [file rootname [file tail $h]]
        }
    }
    set results {} ; set npass 0 ; set nfail 0
    foreach name $tests {
        set hex  $build/$name.hex
        set slog $build/$name.spike.log
        set sim  $build/$name.sim.log
        if {![file exists $hex] || ![file exists $slog]} {
            lappend results [format "MISS  %-10s (no hex/spike.log)" $name] ; incr nfail ; continue
        }

        # capture this test's transcript to its own file
        transcript file $sim
        vsim -quiet -onfinish stop tb_top_opt \
             +UVM_TESTNAME=rvfi_test +PROGRAM=$hex +SPIKE_LOG=$slog
        run $::RV32UI_BOUND
        quit -sim
        transcript file ""

        set fh [open $sim r] ; set data [read $fh] ; close $fh
        set passline [regexp {TEST PASSED} $data]
        set nerr -1 ; set nfat -1
        regexp {UVM_ERROR :\s*(\d+)} $data -> nerr
        regexp {UVM_FATAL :\s*(\d+)} $data -> nfat
        if {$passline && $nerr == 0 && $nfat == 0} {
            lappend results [format "PASS  %-10s" $name] ; incr npass
        } else {
            set clue ""
            if {[regexp {SCOREBOARD_COMPARE[^\r\n]*} $data m]} { set clue [string range $m 0 110] }
            lappend results [format "FAIL  %-10s (pass=%d err=%s fatal=%s) %s" \
                             $name $passline $nerr $nfat $clue]
            incr nfail
        }
    }

    set summary $build/_suite_results.txt
    set out [open $summary w]
    puts "\n============ rv32ui SUITE RESULTS ============"
    foreach r $results { puts $r ; puts $out $r }
    set tot [expr {$npass + $nfail}]
    puts "pass=$npass  fail=$nfail  total=$tot"
    puts $out "pass=$npass  fail=$nfail  total=$tot"
    close $out
    puts "(per-test detail: $build/<test>.sim.log   summary file: $summary)"
}

rv32ui_compile
rv32ui_run
