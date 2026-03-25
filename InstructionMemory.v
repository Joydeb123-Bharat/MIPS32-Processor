`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.03.2026 12:01:49
// Design Name: 
// Module Name: InstructionMemory
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module InstructionMemory(
    input [31:0] PC,
    output [31:0] Inst
    );
    reg [31:0] Inst_Memory [0:1023];
    initial
        begin 
            $readmemb("C:/Users/joyde/OneDrive/Desktop/MIPS32/MIPS32/imem_init.txt", Inst_Memory); 
        end
     assign Inst = Inst_Memory[(PC >> 2)];
endmodule
