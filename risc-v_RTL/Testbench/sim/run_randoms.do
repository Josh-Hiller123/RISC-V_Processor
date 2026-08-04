set ::RAND_BUILD risc-v_RTL/Testbench/programs/randoms/build
set ::RAND_BOUND "500 ms"   ;# 50,000 cycles @ 10us clock; bounds divergent hangs

proc rand_compile {} {
    catch {quit -sim}
    vlib work
    vmap work work
    vlog -sv +define+RVFI -f risc-v_RTL/Testbench/sim/filelist.f
    vopt +acc tb_top -o tb_top_opt
}

proc rand_run {{tests {}}} {
    set build $::RAND_BUILD
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
            lappend results [format "MISS  %-14s (no hex/spike.log)" $name] ; incr nfail ; continue
        }
        transcript file $sim
        vsim -quiet -onfinish stop tb_top_opt \
             +UVM_TESTNAME=rvfi_test +PROGRAM=$hex +SPIKE_LOG=$slog
        run $::RAND_BOUND
        quit -sim
        transcript file ""

        set fh [open $sim r] ; set data [read $fh] ; close $fh
        set passline [regexp {TEST PASSED} $data]
        set nerr -1 ; set nfat -1
        regexp {UVM_ERROR :\s*(\d+)} $data -> nerr
        regexp {UVM_FATAL :\s*(\d+)} $data -> nfat
        if {$passline && $nerr == 0 && $nfat == 0} {
            lappend results [format "PASS  %-14s" $name] ; incr npass
        } else {
            set clue ""
            if {[regexp {SCOREBOARD_COMPARE[^\r\n]*} $data m]} { set clue [string range $m 0 110] }
            lappend results [format "FAIL  %-14s (pass=%d err=%s fatal=%s) %s" \
                             $name $passline $nerr $nfat $clue]
            incr nfail
        }
    }
    set summary $build/_rand_results.txt
    set out [open $summary w]
    puts "\n========= CONSTRAINED-RANDOM SUITE RESULTS ========="
    foreach r $results { puts $r ; puts $out $r }
    set tot [expr {$npass + $nfail}]
    puts "pass=$npass  fail=$nfail  total=$tot"
    puts $out "pass=$npass  fail=$nfail  total=$tot"
    close $out
    puts "(per-seed detail: $build/rand_<seed>.sim.log   summary: $summary)"
}

rand_compile
rand_run
