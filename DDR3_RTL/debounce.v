module debounce(
    input clk, 		
	 input reset_n, 
    input idebounce,
    output reg odebounce  
);

parameter NDELAY = 1000000;
parameter NBITS = 20;

reg [NBITS-1:0] count;
reg xnew;
	
always@(posedge clk or negedge reset_n)
begin
  if(!reset_n)
  begin
    xnew <= idebounce;
	 odebounce <= idebounce;
	 count <= 0;
  end
  else if(idebounce != xnew)
  begin
    xnew <= idebounce;
	 count <= 0;
  end
  else if(count == NDELAY)
    odebounce <= xnew;
  else
    count <= count+1;
end
endmodule 