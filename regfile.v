module regFile(output [31:0] rs2_value,
               output [31:0] rs1_value,
               output [95:0] debug_register,
               input [4:0] rs1_address,
               input [4:0] rs2_address,
               input [4:0] wr_address,
               input [31:0] wr_value,
               input we,
               input clk,
               input reset,
               output [32*32-1:0] registers_rfile
               ); // 32 registers(31 general purpose)
reg [31:0]  registerArray [31:0];
wire [95:0] debug_register;
// register value outputs(rs1 and rs2) = >asynchronous combinational reads,hence assign
assign rs1_value = registerArray[rs1_address];
assign rs2_value = registerArray[rs2_address];
assign debug_register = {registerArray[1],registerArray[2],registerArray[31]};
assign registers_rfile = {registerArray[31], registerArray[30], registerArray[29], registerArray[28], registerArray[27], registerArray[26], registerArray[25], registerArray[24], registerArray[23], registerArray[22], registerArray[21], registerArray[20], registerArray[19], registerArray[18], registerArray[17], registerArray[16], registerArray[15], registerArray[14], registerArray[13], registerArray[12], registerArray[11], registerArray[10], registerArray[9], registerArray[8], registerArray[7], registerArray[6], registerArray[5], registerArray[4], registerArray[3], registerArray[2], registerArray[1], registerArray[0]};
integer i;
integer j;
// initialising all the registers with 0 values
initial
begin
    for(i = 0;i<32;i = i+1) registerArray[i] = 32'b0;
end

always @(posedge clk)
begin
    if (reset)
    begin
        for(i = 0;i<32;i = i+1)
        begin
            registerArray[i] <= 32'b0;
        end
    end
    else
    begin
        if (we)
        begin
            if (wr_address == 32'd0)
            begin
                registerArray[0] <= 32'b0;
            end
            else
            begin
                registerArray[wr_address] <= wr_value;
            end
        end
    end
    /* else: check if synthesis is failing  */
end
endmodule
