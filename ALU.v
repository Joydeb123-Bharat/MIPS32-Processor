`timescale 1ns / 1ps

module ALU(
    input [31:0] A,
    input [31:0] B,
    output reg [31:0] ALU_Out,
    input [5:0] ALU_Control // Taking the full 6-bit opcode
    );
    
    parameter ADD  = 6'b000000, SUB  = 6'b000001, AND  = 6'b000010, 
              OR   = 6'b000011, SLT  = 6'b000100, MUL  = 6'b000101,
              LW   = 6'b001000, SW   = 6'b001001, 
              ADDI = 6'b001010, SUBI = 6'b001011, SLTI = 6'b001100,
              BNEQZ = 6'b001101, 
              BEQZ  = 6'b001110;
              
    always @(*) begin
        case(ALU_Control)
            ADD, ADDI, LW, SW, BEQZ, BNEQZ: ALU_Out = A + B;
            SUB, SUBI:         ALU_Out = A - B;  
            OR:                ALU_Out = A | B;
            AND:               ALU_Out = A & B;
            SLT, SLTI:         ALU_Out = (A < B) ? 32'b1 : 32'b0;
            MUL:               ALU_Out = A * B;
            default:           ALU_Out = A;
        endcase
    end              
endmodule