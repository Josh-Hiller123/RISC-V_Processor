package tb_commit_struct; 
    typedef struct {
        logic [31:0] pc_commit;
        logic [31:0] instruct_commit;
        logic wenable_commit;
        logic [4:0]  rd_commit;
        logic [31:0] rd_data_commit;
        logic mem_write_commit;
        logic [31:0] mem_addr_commit;
        logic [31:0] mem_data_commit;
    } spike_commit_t;
endpackage 