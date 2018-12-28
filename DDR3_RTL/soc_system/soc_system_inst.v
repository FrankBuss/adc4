	soc_system u0 (
		.clk_clk                                (<connected-to-clk_clk>),                                //                       clk.clk
		.ddr3_clk_clk                           (<connected-to-ddr3_clk_clk>),                           //                  ddr3_clk.clk
		.ddr3_hps_f2h_sdram0_clock_clk          (<connected-to-ddr3_hps_f2h_sdram0_clock_clk>),          // ddr3_hps_f2h_sdram0_clock.clk
		.ddr3_hps_f2h_sdram0_data_address       (<connected-to-ddr3_hps_f2h_sdram0_data_address>),       //  ddr3_hps_f2h_sdram0_data.address
		.ddr3_hps_f2h_sdram0_data_read          (<connected-to-ddr3_hps_f2h_sdram0_data_read>),          //                          .read
		.ddr3_hps_f2h_sdram0_data_readdata      (<connected-to-ddr3_hps_f2h_sdram0_data_readdata>),      //                          .readdata
		.ddr3_hps_f2h_sdram0_data_write         (<connected-to-ddr3_hps_f2h_sdram0_data_write>),         //                          .write
		.ddr3_hps_f2h_sdram0_data_writedata     (<connected-to-ddr3_hps_f2h_sdram0_data_writedata>),     //                          .writedata
		.ddr3_hps_f2h_sdram0_data_readdatavalid (<connected-to-ddr3_hps_f2h_sdram0_data_readdatavalid>), //                          .readdatavalid
		.ddr3_hps_f2h_sdram0_data_waitrequest   (<connected-to-ddr3_hps_f2h_sdram0_data_waitrequest>),   //                          .waitrequest
		.ddr3_hps_f2h_sdram0_data_byteenable    (<connected-to-ddr3_hps_f2h_sdram0_data_byteenable>),    //                          .byteenable
		.ddr3_hps_f2h_sdram0_data_burstcount    (<connected-to-ddr3_hps_f2h_sdram0_data_burstcount>),    //                          .burstcount
		.memory_mem_a                           (<connected-to-memory_mem_a>),                           //                    memory.mem_a
		.memory_mem_ba                          (<connected-to-memory_mem_ba>),                          //                          .mem_ba
		.memory_mem_ck                          (<connected-to-memory_mem_ck>),                          //                          .mem_ck
		.memory_mem_ck_n                        (<connected-to-memory_mem_ck_n>),                        //                          .mem_ck_n
		.memory_mem_cke                         (<connected-to-memory_mem_cke>),                         //                          .mem_cke
		.memory_mem_cs_n                        (<connected-to-memory_mem_cs_n>),                        //                          .mem_cs_n
		.memory_mem_ras_n                       (<connected-to-memory_mem_ras_n>),                       //                          .mem_ras_n
		.memory_mem_cas_n                       (<connected-to-memory_mem_cas_n>),                       //                          .mem_cas_n
		.memory_mem_we_n                        (<connected-to-memory_mem_we_n>),                        //                          .mem_we_n
		.memory_mem_reset_n                     (<connected-to-memory_mem_reset_n>),                     //                          .mem_reset_n
		.memory_mem_dq                          (<connected-to-memory_mem_dq>),                          //                          .mem_dq
		.memory_mem_dqs                         (<connected-to-memory_mem_dqs>),                         //                          .mem_dqs
		.memory_mem_dqs_n                       (<connected-to-memory_mem_dqs_n>),                       //                          .mem_dqs_n
		.memory_mem_odt                         (<connected-to-memory_mem_odt>),                         //                          .mem_odt
		.memory_mem_dm                          (<connected-to-memory_mem_dm>),                          //                          .mem_dm
		.memory_oct_rzqin                       (<connected-to-memory_oct_rzqin>)                        //                          .oct_rzqin
	);

