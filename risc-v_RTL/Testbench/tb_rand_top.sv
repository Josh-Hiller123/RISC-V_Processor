module tb_rand_top;
import tb_rand_package::*;
initial begin
    int programs_amt; 
    int start_seed;
    string directory;

    if (!$value$plusargs("NUM=%d", programs_amt)) 
        programs_amt = 50; 

    if (!$value$plusargs("START=%d",  start_seed)) 
        start_seed = 0;

    if (!$value$plusargs("DIR=%s", directory)) 
        $fatal(1, "No directory specified for program generation"); 
    
    for (int s = start_seed; s < start_seed + programs_amt; s++) begin
      automatic program_generate program_g = new(s);
      program_g.program_write();
      program_g.file_write($sformatf("%s/rand_%0d.S", directory, s));
    end
    $display("[gen_top] wrote %0d programs (seeds %0d..%0d) to %s", programs_amt, start_seed, start_seed + programs_amt - 1, directory);
    $finish;
  end
endmodule