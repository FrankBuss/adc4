module Avalon_bus_RW_Test(
		iCLK,
		iRST_n,
		insert_error,
		
		
		avl_waitrequest,                 
		avl_address,                      
		avl_readdatavalid,                 
		avl_readdata,                      
		avl_writedata,                     
		avl_read,                          
		avl_write,    
		avl_burstbegin,
		avl_size,
		
		drv_status_pass,
		drv_status_fail,
		drv_status_test_complete
		
								);

input 						 iCLK;
input							 iRST_n;

input 						 insert_error;
input          			 avl_waitrequest;                 //             avl.waitrequest_n
input          			 avl_readdatavalid;                 //                .readdatavalid
input  		[DATA_W-1:0] avl_readdata;                      //                .readdata

output 		[ADDR_W-1:0] avl_address;                       //                .address
output 		[DATA_W-1:0] avl_writedata;                     //                .writedata
output         		 avl_read;                          //                .read
output         		 avl_write;                         //                .write
output					reg drv_status_pass;
output					reg drv_status_fail;
output					reg drv_status_test_complete;
output					    avl_burstbegin;
output      [7:0]			 avl_size;
wire 							 max_avl_address;



parameter      ADDR_W             = 26;
parameter      DATA_W             = 128;
parameter      LFSR_SEED = 36'b00111110000011110000111000110010;
`define        ADDR    26'h3ffffff
`define  		BURST_LENGTH 		   1
`define 			WRITE_STATE			   0
`define 			READ_STATE			   1
`define 			FINISH_STATE			2
assign  avl_size          = `BURST_LENGTH;
assign  max_avl_address   = (avl_address==`ADDR-(`BURST_LENGTH-1))?1'b1:1'b0;

lfsr_wrapper write_data_gen_inst (
	.clk		(iCLK),
	.reset_n	(iRST_n),
	.enable	(local_init_done & avl_waitrequest_n & !RW_State & avl_write ),
	.data		(avl_writedata)
	);
defparam read_data_gen_inst.DATA_WIDTH 	= DATA_W;
defparam read_data_gen_inst.SEED       	= LFSR_SEED;

	
// Pseudo-random data generator
lfsr_wrapper read_data_gen_inst (
	.clk		(iCLK),
	.reset_n	(iRST_n & insert_error),
	.enable	(local_init_done & avl_readdatavalid),
	.data		(avl_expected_data)
	);
defparam write_data_gen_inst.DATA_WIDTH	= DATA_W;
defparam write_data_gen_inst.SEED       	= LFSR_SEED;



reg 			[1:0] 		 RW_State;
reg         [ADDR_W-1:0] avl_address;           
reg         [3:0]			 w_burst_cnt;
reg   						 write_latency;
always @ (posedge iCLK or negedge iRST_n)
begin
	if(!iRST_n)
	begin
	    RW_State <= 0;
	    write_latency <= 0;
	    avl_address <= 0;
	    drv_status_test_complete <= 0;
	    w_burst_cnt <= 0;
	end
	else 
	begin 
     case(RW_State)
	  0:begin
	      if(!avl_waitrequest & !max_avl_address)
			begin
			  if(w_burst_cnt == `BURST_LENGTH-1)
		     begin
			    avl_address <= avl_address + `BURST_LENGTH;
		       w_burst_cnt <= 0;
		     end
	        else
		       w_burst_cnt <= w_burst_cnt +1;
		   end
			
			else if(!avl_waitrequest & max_avl_address )
			begin
			  if(w_burst_cnt == `BURST_LENGTH-1)
			  begin
				 avl_address <= 0;
				 RW_State <= 1;
			  end
			  else
			    w_burst_cnt <= w_burst_cnt +1;
			end
			
			else
		      w_burst_cnt <= w_burst_cnt;
	    end
		 
	  
	  1:begin
	      if(!avl_waitrequest & !max_avl_address & avl_read)
			  avl_address <= avl_address + `BURST_LENGTH;
			else if(!avl_waitrequest & max_avl_address )
			begin
			  avl_address <= 0;
	        RW_State <= 2;
			end
			else
			  avl_address <= avl_address;
	    end
	  
	  2:begin
	      if(r_addr == `ADDR)
			  drv_status_test_complete <= 1;
			else
			  drv_status_test_complete <= drv_status_test_complete;
	    end
	  
	  endcase
   end
end

assign avl_write = (RW_State==0 && iRST_n==1)?1:0;
assign avl_read  = (RW_State==1 && iRST_n==1)?1:0;


reg 			[ADDR_W-1:0] r_addr;  
wire        [DATA_W-1:0] avl_expected_data;      
               
always@(posedge iCLK or negedge iRST_n)
begin
  if(!iRST_n)
  begin
    drv_status_fail <= 0;
	 r_addr <= 0;
  end
  else 
  begin
    if(compare_enable && (compare_read_data == compare_excepted_data))
      r_addr <= r_addr +1;
	 else if(compare_enable && (compare_read_data != compare_excepted_data))
	 begin
	   r_addr <= r_addr +1;
	   drv_status_fail <= 1;
	 end
	 else 
	   drv_status_fail <= drv_status_fail;	
  end
end						

reg [DATA_W-1:0] compare_read_data;
reg [DATA_W-1:0] compare_excepted_data;
reg            compare_enable;

always@(posedge iCLK or negedge iRST_n)
begin
  if(!iRST_n)
  begin
	 compare_excepted_data <= 0;
	 compare_enable <= 0;
	 compare_read_data <= 0;
  end
  else
  begin
    if(avl_readdatavalid)
	 begin
		compare_excepted_data <= avl_expected_data;
		compare_read_data <= avl_readdata;
		compare_enable <= 1;
	 end
	 else
	 begin
		compare_excepted_data <= avl_expected_data;
		compare_read_data <= compare_read_data;
		compare_enable <= 0;
	 end
	 
  end
end



always@(posedge iCLK or negedge iRST_n)
begin
  if(!iRST_n)
    drv_status_pass <= 0;
  else
  begin
    if(r_addr == `ADDR && drv_status_fail ==0)
      drv_status_pass  <= 1;
	 else
	   drv_status_pass <= drv_status_pass;
  end
end
	 
	 
endmodule 
