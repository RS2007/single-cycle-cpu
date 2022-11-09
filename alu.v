module alu(output [31:0] aluResult,
           input [6:0] opcode,
           input [31:0] registerValue1,
           input [31:0] registerValue2,
           input [2:0] funct3,
           input [6:0] funct7,
           input [11:0] imm);
/* wire [11:0] imm; */
/* wire [6:0] funct7; */
/* wire [2:0] funct3; */
/* wire [5:0] opcode; */
/* wire [4:0] rs1; */
/* wire [4:0] rs2; */
reg [31:0] aluResult;
wire [31:0] sextImm;
wire isImmediate;
wire [4:0] shamt;

localparam ADDI_funct3 = 3'b000,
SLTI_funct3 = 3'b010,
SLTIU_funct3 = 3'b011,
XORI_funct3 = 3'b100,
ORI_funct3 = 3'b110,
ANDI_funct3 = 3'b111,
SLLI_funct3 = 3'b001,
SRLIandSRAI_funct3 = 3'b101;

localparam ADD_SUB_funct3 = 3'b000,
SLL_funct3 = 3'b001,
SLT_funct3 = 3'b010,
SLTU_funct3 = 3'b011,
XOR_funct3 = 3'b100,
SRLandSRA_funct3 = 3'b101,
OR_funct3 = 3'b110,
AND_funct3 = 3'b111;

assign isNotImmediate = opcode[5];
assign sextImm        = {{20{imm[11]}},imm};
assign shamt          = {{27{1'b0}},imm[4:0]};
always @(*)
begin
  if({opcode[4],opcode[2]} == 2'b10)
  begin
    if (~isNotImmediate)
    begin
        case(funct3)
            ADDI_funct3:begin
                aluResult = registerValue1 + sextImm;
            end
            SLTI_funct3:
            begin
                if ($signed(registerValue1)<$signed(sextImm))
                begin
                    aluResult = 32'b1;
                end
                else
                begin
                    aluResult = 32'b0;
                end
            end
            SLTIU_funct3:
            begin
                if (registerValue1 < sextImm)
                begin
                    aluResult = 32'b1;
                end
                else
                begin
                    aluResult = 32'b0;
                end
            end
            XORI_funct3:
            begin 
                aluResult = registerValue1 ^ sextImm;
            end
            ORI_funct3: aluResult  = registerValue1 | sextImm;
            ANDI_funct3: aluResult = registerValue1 & sextImm;
            SLLI_funct3: aluResult = registerValue1 << shamt;
            SRLIandSRAI_funct3:
            begin
                if (funct7[5]) aluResult = registerValue1 >> shamt ;         //SRAI
                else aluResult           = $signed(registerValue1) >>> shamt;//SRLI
            end
            default: aluResult = 32'b0;
        endcase
    end
    else
    begin
        case(funct3)
            ADD_SUB_funct3:
            begin
                if (funct7[5])
                begin
                    aluResult = registerValue1 - registerValue2;
                end
                else
                begin
                    aluResult = registerValue1 + registerValue2;
                end
            end
            SLL_funct3: aluResult = registerValue1 << registerValue2[4:0];
            SLT_funct3:
            begin
                if ($signed(registerValue1)<$signed(registerValue2))
                begin
                    aluResult = 32'b1;
                end
                else
                begin
                    aluResult = 32'b0;
                end
            end
            
            SLTU_funct3:
            begin
                if (registerValue1<registerValue2)
                begin
                    aluResult = 32'b1;
                end
                else
                begin
                    aluResult = 32'b0;
                end
            end
            XOR_funct3: aluResult = registerValue1 ^ registerValue2;
            SRLandSRA_funct3:
            begin
                if (funct7[5]) aluResult = registerValue1 >> registerValue2[4:0];
                else aluResult           = $signed(registerValue1) >>> registerValue2[4:0];
            end
            AND_funct3: aluResult = registerValue1 & registerValue2;
            OR_funct3: aluResult  = registerValue1 | registerValue2;
            default: aluResult    = 32'b0;
        endcase
    end
end
else aluResult = 32'd0;
end

endmodule

