module cpu (input clk,
            input reset,
            output [31:0] iaddr,
            input [31:0] idata,
            output [31:0] daddr,
            input [31:0] drdata,
            output [31:0] dwdata,
            output [3:0] dwe);
    reg [31:0] iaddr;
    reg [31:0] daddr;
    reg [31:0] dwdata;
    reg [11:0] imm;
    reg [3:0]  dwe                  = 4'b000;
    reg registerWriteEnableRegister = 1'b1;
    reg [31:0] writeValue           = 32'd0;
    reg [31:0] iaddr_wire;
    
    
    
    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [6:0] funct7;
    wire registerWriteEnableWire;
    wire [31:0] registerValue1,registerValue2,aluResult;
    wire [31:0] signExtendedIdata;
    wire [11:0] immStore;
    wire [11:0] immALU;
    wire [11:0] immBranch;
    wire [31:0] immJAL;
    wire [11:0] immJALR;
    wire [95:0] debug_register;
    assign opcode                  = idata[6:0];
    assign rd                      = idata[11:7];
    assign rs1                     = idata[19:15];
    assign rs2                     = idata[24:20];
    assign funct3                  = idata[14:12];
    assign funct7                  = idata[31:25];
    assign registerWriteEnableWire = registerWriteEnableRegister;
    assign immStore                = {idata[31:25],idata[11:7]};
    assign immALU                  = idata[31:20];
    assign signExtendedIdata       = idata[registerValue1+{{20{imm[11]}},imm}];
    assign immBranch               = {idata[31], idata[7], idata[30:25], idata[11:8], 1'b0};
    assign immJAL = {{12{idata[31]}}, idata[19:12], idata[20], idata[30:21], {1'b0}};
    assign immJALR = idata[31:20];
    localparam LOAD = 7'b0000011,
    STORE = 7'b0100011,
    LUI = 7'b0110111,
    AUIPC = 7'b0010111,
    JAL = 7'b1101111,
    JALR = 7'b1100111,
    BRANCH = 7'b1100011;
    
    
    localparam LB = 3'b000,
    LH = 3'b001,
    LW = 3'b010,
    LBU = 3'b100,
    LHU = 3'b101;
    
    
    localparam SB = 3'b000,
    SH = 3'b001,
    SW = 3'b010;
    
    localparam
    BEQ = 3'b000,
    BNE = 3'b001,
    BLT = 3'b100,
    BGE = 3'b101,
    BLTU = 3'b110,
    BGEU = 3'b111;
    
    regFile registers(
    .rs2_value(registerValue2),
    .rs1_value(registerValue1),
    .debug_register(debug_register),
    .rs1_address(rs1),
    .rs2_address(rs2),
    .wr_address(rd),
    .wr_value(writeValue),
    .we(registerWriteEnableWire),
    .clk(clk),
    .reset(reset)
    );
    
    alu alu32Bit(
    .aluResult(aluResult),
    .opcode(opcode),
    .registerValue1(registerValue1),
    .registerValue2(registerValue2),
    .funct3(funct3),
    .funct7(funct7),
    .imm(imm)
    );
    
    imem IMEM(
    .iaddr(iaddr),
    .idata(idata)
    );
    
    dmem DMEM(
    .clk(clk),
    .daddr(daddr),
    .dwdata(dwdata),
    .dwe(dwe),
    .drdata(drdata)
    );
    
    
    always @(*)
    begin
        // if(iaddr == 32'h0000083c) $display("in");
        if (opcode == LOAD)
        begin
            dwe = 4'b0000;
            imm = immALU;
            case(funct3)
                LB:
                begin
                    dwe                         = 4'b0000;
                    daddr                       = registerValue1 + $signed({{20{imm[11]}},imm});
                    writeValue                  = {{24{drdata[7]}},drdata[7:0]};
                    registerWriteEnableRegister = 1;
                    /* if (idata == 32'h00000103) $finish(); */
                end
                LH:
                begin
                    registerWriteEnableRegister = 1;
                    dwe                         = 4'b0000;
                    daddr                       = registerValue1 + $signed({{20{imm[11]}},imm});
                    writeValue                  = {{16{drdata[15]}},{drdata[15:0]}};
                    /* if (idata == 32'h00001103) $finish(); */
                    /* drDataSizeAdjusted <= drdata; */
                end
                LW:
                begin
                    registerWriteEnableRegister = 1;
                    dwe                         = 4'b0000;
                    daddr                       = registerValue1 + $signed({{20{idata[31]}},idata[31:20]});
                    writeValue                  = drdata;
                    /* if (idata == 32'h00802203) */
                    /* begin */
                        /*   $display("Problem lies here"); */
                        /*   $finish(); */
                    /* end */
                    /* if (idata == 32'hfec42783) $finish(); */
                    /* drDataSizeAdjusted <= drdata; */
                end LBU:
                begin
                    registerWriteEnableRegister = 1;
                    dwe                         = 4'b0000;
                    daddr                       = registerValue1 + $signed({{20{imm[11]}},imm});
                    writeValue                  = {24'b0,drdata[7:0]};
                end
                LHU:
                begin
                    registerWriteEnableRegister = 1;
                    dwe                         = 4'b0000;
                    daddr                       = registerValue1 + $signed({{20{imm[11]}},imm});
                    writeValue                  = {16'b0,drdata[15:0]};
                end
                default: registerWriteEnableRegister = 0;
            endcase
            iaddr_wire = iaddr + 4;
        end
        else if (opcode == STORE)
            begin imm = immStore;
            case(funct3)
                SB:
                begin
                    registerWriteEnableRegister = 0;
                    dwdata                      = {4{registerValue2[7:0]}};
                    daddr                       = registerValue1 + $signed({{20{imm[11]}},imm});
                    case(immStore[1:0])
                        2'd0: dwe = 4'b0001;
                        2'd1: dwe = 4'b0010;
                        2'd2: dwe = 4'b0100;
                        2'd3: dwe = 4'b1000;
                        default: $display("Error");
                    endcase
                end
                SH:
                begin
                    registerWriteEnableRegister = 0;
                    /* if (idata == 32'h00101023) $finish(); */
                    case(immStore[1:0])
                        2'd0:
                        begin
                            dwe    = 4'b0011;
                            dwdata = {16'b0,registerValue2[15:0]};
                            daddr  = registerValue1 + $signed({{20{imm[11]}},imm});
                        end
                        2'd2:
                        begin
                            dwe    = 4'b1100;
                            dwdata = {registerValue2[15:0],16'b0};
                            daddr  = registerValue1 + $signed({{20{imm[11]}},imm});
                        end
                    endcase
                end
                SW:
                begin
                    registerWriteEnableRegister = 0;
                    if (immStore[1:0] == 0)
                    begin
                        dwe    = 4'b1111;
                        dwdata = registerValue2;
                        daddr  = registerValue1 + $signed({{20{imm[11]}},imm});
                    end
                    else
                    begin
                        $display("Error");
                    end
                end
                default:registerWriteEnableRegister = 1;
            endcase
            iaddr_wire = iaddr + 4;
            end
        else if ({opcode[4],opcode[2]} == 2'b10)
        begin
            dwe                         = 4'b0000;
            registerWriteEnableRegister = 1;
            imm                         = immALU;
            writeValue                  = aluResult;
            iaddr_wire = iaddr + 4;
        end
            else if (opcode == LUI)
            begin
            registerWriteEnableRegister = 1;
            writeValue                  = {idata[31:12],12'b0};
            iaddr_wire = iaddr + 4;
            end
            else if (opcode == AUIPC)
            begin
            registerWriteEnableRegister = 1;
            writeValue                  = iaddr + {idata[31:12],12'b0};
            iaddr_wire = iaddr + 4;
            end
            else if (opcode == JAL)
            begin
                registerWriteEnableRegister = 1;
                writeValue = iaddr + 4;
                iaddr_wire = iaddr + immJAL;
            end
            else if (opcode == JALR)
            begin
                registerWriteEnableRegister = 1;
                writeValue = iaddr + 4;
                iaddr_wire = (($signed({{20{immJALR[11]}},immJALR})+registerValue1) >> 1) << 1;
            end
            else if (opcode == BRANCH)
            begin
                case(funct3)
                    BEQ:
                    begin
                        registerWriteEnableRegister = 0;
                        dwe = 4'b000;
                        if ($signed(registerValue1) == $signed(registerValue2)) iaddr_wire = iaddr + {{20{immBranch[11]}},immBranch};
                        else
                        begin 
                            iaddr_wire = iaddr + 4;
                        end
                    end
                    BNE:
                    begin
                        registerWriteEnableRegister = 0;
                        dwe = 4'b000;
                        if ($signed(registerValue1) != $signed(registerValue2)) iaddr_wire = iaddr + {{20{immBranch[11]}},immBranch};
                        else
                        begin
                             iaddr_wire = iaddr + 4;
                        end
                    end
                    BLT:
                    begin
                        registerWriteEnableRegister = 0;
                        dwe = 4'b000;
                        if ($signed(registerValue1) < $signed(registerValue2)) iaddr_wire = iaddr + {{20{immBranch[11]}},immBranch};
                        else
                        begin
                         iaddr_wire = iaddr + 4;
                        end
                    end
                    BGE:
                    begin
                        registerWriteEnableRegister = 0;
                        dwe = 4'b000;
                        if ($signed(registerValue1) >= $signed(registerValue2)) iaddr_wire = iaddr + {{20{immBranch[11]}},immBranch};
                        else
                        begin
                             iaddr_wire = iaddr + 4;
                        end
                    end
                    BLTU:
                    begin
                        registerWriteEnableRegister = 0;
                        dwe = 4'b000;
                        if ($unsigned(registerValue1) < $unsigned(registerValue2)) iaddr_wire = iaddr + {{20{immBranch[11]}},immBranch};
                        else
                        begin
                             iaddr_wire = iaddr + 4;
                        end
                    end
                    BGEU:
                    begin
                        registerWriteEnableRegister = 0;
                        dwe = 4'b000;
                        if ($unsigned(registerValue1) > $unsigned(registerValue2)) iaddr_wire = iaddr + {{20{immBranch[11]}},immBranch};
                        else
                        begin
                             iaddr_wire = iaddr + 4;
                        end
                    end
                    default: $display("Error from opcode: %7b, funct3: %3b",opcode,funct3);
                endcase
            end
            else if(opcode == 7'd0 || idata == 32'd0)
            begin
                registerWriteEnableRegister = 0;
                iaddr_wire = iaddr + 4;
            end
            else
            begin
                registerWriteEnableRegister = 0;
                iaddr_wire = iaddr + 4;
            end
            end
            
            always @(posedge clk)
            begin
                if (reset)
                begin
                    iaddr  <= 0;
                    daddr  <= 0;
                    dwdata <= 0;
                    dwe    <= 0;
                end
                /* else if (opcode == 7'b0000000) begin */
                /*     registerWriteEnableRegister <= 0; */
                /*     dwe                         <= 4'b0000; */
                /* end */
                else
                begin
                //branch logic
                
                iaddr <= iaddr_wire;
            end
            
            end
            
            
            
            endmodule
