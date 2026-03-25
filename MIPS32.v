`timescale 1ns / 1ps

module MIPS32(
    input clk,
    input start,
    input rst,
    output reg done
    );
    
    // 1. Registers
    reg [31:0] PC, NPC; 
    reg [31:0] A, B, Imm; 
    reg [31:0] TR, LD, IR; 
    reg Zero; //Zero Flag
    
    // 2. Control Signals
    reg isBranch, isImm, isLoad, isAdd;
    reg RB_E, Mem_E; 
    reg RB_W, Mem_W; 
    reg [2:0] state; 
    reg Start;
    
    // Parameters
    parameter START = 3'b101, STOP = 3'b010, IF = 3'b000, ID = 3'b001, EX = 3'b011, MEM = 3'b111, WB = 3'b110, NINST =3'b100;
    
    // 3. Interconnect Wires
    wire [31:0] InstMem_IR, D1, D2, ALU_TR, MEMorALU;//AddCal;
    wire [31:0] wire_A, wire_B, wire_LD; // Temp wires for module outputs
    wire [4:0] TargetorDest;
    
    // 4. Multiplexer Connections
    assign D1 = isAdd ? NPC : A; 
    assign D2 = isImm ? (isAdd ? (Imm << 2) : Imm) : B;
    assign MEMorALU = isLoad ? LD : TR;
    assign TargetorDest = IR[29] ? IR[20:16] : IR[15:11];
    //assign AddCal = (Zero & isBranch) ? TR : NPC;
    // 5. Instantiations 
    ALU alu(
        .A(D1), 
        .B(D2), 
        .ALU_Control(IR[31:26]), 
        .ALU_Out(ALU_TR)          
    );
    InstructionMemory IM(
        .PC(PC), 
        .Inst(InstMem_IR)
    );
    RegisterBank RB(
        .clk(clk), 
        .rst(rst), 
        .RB_W(RB_W), 
        .RB_E(RB_E), 
        .rs(IR[25:21]), 
        .rt(IR[20:16]), 
        .rd(TargetorDest), 
        .Imm(MEMorALU), 
        .RS1(wire_A),           
        .RS2(wire_B)            
    );
    DataMemory DM(
        .clk(clk), 
        .rst(rst), 
        .Mem_W(Mem_W), 
        .Mem_E(Mem_E), 
        .Add(TR), 
        .DataIn(B), 
        .DataOut(wire_LD)      
    );
    
    // INSTRUCTION OPCODES (For FSM Decoding)
    // R-Type Instructions (Arithmetic & Logic)
    parameter ADD  = 6'b000000, 
              SUB  = 6'b000001, 
              AND  = 6'b000010, 
              OR   = 6'b000011, 
              SLT  = 6'b000100, 
              MUL  = 6'b000101, 
              HLT  = 6'b111111; // Halt
    // I-Type Instructions (Memory)
    parameter LW   = 6'b001000, 
              SW   = 6'b001001;
    // I-Type Instructions (Immediate Arithmetic)
    parameter ADDI = 6'b001010, 
              SUBI = 6'b001011, 
              SLTI = 6'b001100;
    // I-Type Instructions (Branching)
    parameter BNEQZ = 6'b001101, 
              BEQZ  = 6'b001110;
    
    //ASM
    always@(posedge clk or posedge rst)
        begin
            if(rst)            
                begin
                    PC  <= 32'd0;
                    NPC <= 32'd0;
                    IR  <= 32'd0;
                    A   <= 32'd0;
                    B   <= 32'd0;
                    Imm <= 32'd0;
                    TR  <= 32'd0; 
                    LD  <= 32'd0;
                    done <= 1'b0;
                    RB_E <= 0;
                    RB_W  <= 1'b0;
                    Mem_W <= 1'b0;
                    Mem_E <= 1'b0;
                    state <= START;
                    isBranch <= 0;
                    isImm <= 0;
                    isLoad <= 0;
                    isAdd <= 0;
                end
           else if(start)
            begin
                Start <= 1;
            end
           
       end
       always @(posedge clk) begin 
        if (Start) begin
            case(state)
                START: begin
                    // Move to the Instruction Fetch state on the next clock
                    NPC <= PC + 4;
                    A <= 0;
                    B <= 0;
                    TR <= 0;
                    LD <= 0;
                    Imm <= 0;
                    Zero <= 0;
                    isBranch <= 0;
                    isLoad <= 0;
                    isImm <= 0;
                    isAdd <= 0;
                    RB_E <= 0;
                    RB_W <= 0;
                    Mem_E <= 0;
                    Mem_W <= 0;
                    state <= IF;
                end
                
                IF: begin
                    // 1. Fetch instruction from memory into IR
                    IR <= InstMem_IR; 
                    RB_E <= 1;
                    // 3. Move to Instruction Decode
                    state <= ID;
                end
                
                ID: begin
                    //Read Register Bank data into A and B buffers
                    A <= wire_A;
                    B <= wire_B;
                    Imm <= {IR[15] ? 16'hFFFF : 16'h0000, IR[15:0]};
                    case(IR[31:26])
                        ADD,SUB,AND,OR,MUL,SLT: begin
                            isAdd <= 0;
                            isImm <= 0;
                            isLoad <= 0;
                        end
                        ADDI,SUBI,SLTI: begin
                            isAdd <= 0;
                            isImm <= 1;
                            isLoad <= 0;
                        end
                        HLT: begin
                            Start <= 0;
                            done <= 1;
                        end
                        BNEQZ, BEQZ: begin
                            isAdd <= 1;
                            isImm <= 1;
                            isLoad <= 0;
                        end
                        LW, SW: begin
                            isAdd <= 0;
                            isImm <= 1;
                            if(IR[31:26] == SW)begin
                                Mem_W <= 1;
                                isLoad <= 0;
                            end
                            else
                                begin
                                Mem_W <= 0;
                                isLoad <= 1;
                                end
                         end
                     endcase   
                    //Move to Execute
                    state <= EX;
                end
                EX: begin
                    TR <= ALU_TR;
                    Zero <= (wire_A == 0) ? 1 : 0;
                    case(IR[31:26])
                        ADD, SUB, AND, OR, SLT, MUL, ADDI, SUBI, SLTI: begin
                            // R-Types skip Memory and go straight to Write Back
                            state <= WB;
                        end
                        LW,SW: begin
                            // Memory instructions go to the MEM state
                            state <= MEM;
                            Mem_E <= 1;
                        end
                        // You will add your Branching (BEQZ, BNEQZ) cases here!
                        BEQZ,BNEQZ:
                            begin
                                state <= NINST;
                            end
                    endcase
                end
                MEM:
                    begin
                        if(IR[31:26] == LW)
                        begin
                            LD <= wire_LD;
                            state <= WB;
                        end
                        else
                        state <= NINST;
                    end
                WB:
                    begin
                        RB_W <= 1;
                        state <= NINST;
                    end
                NINST: //Loading of the PC
                    begin
                        if((IR[31:26] == BEQZ && Zero) | (IR[31:26] == BNEQZ && ~Zero))
                            PC <= TR;
                        else
                            PC <= NPC;
                        state <= START;
                    end
             endcase
        end
    end         
                                                     
endmodule