`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.03.2026 12:08:29
// Design Name: 
// Module Name: DataMemory
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


module DataMemory(
    input clk,
    input rst,
    input Mem_W,
    input Mem_E,
    input [31:0] Add,
    input [31:0] DataIn,
    output [31:0] DataOut
    );
    reg [31:0] RAM [0:1023];
    integer i;
    assign DataOut = (Mem_E != 0) ? ((Mem_W == 0) ? RAM[Add[11:2]] : 32'b0) : 32'b0;
    always@(posedge clk or posedge rst)
        begin
            if(rst)
                begin
                for( i = 0; i < 1024; i = i + 1)
                    begin
                        RAM[i] <= 32'b0;
                    end
                end
             else
                begin
                    if(Mem_E && Mem_W)
                        begin
                            RAM[Add[11:2]] <= DataIn;
                        end
                end
         end                       
            
endmodule
