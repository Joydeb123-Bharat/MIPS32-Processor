`timescale 1ns / 1ps

module RegisterBank(
    input clk,
    input rst,
    input RB_W,           // Write Enable
    input RB_E,           // Read/Bank Enable (Your custom gating signal)
    input [4:0] rs,       // Source 1 address
    input [4:0] rt,       // Source 2 address
    input [4:0] rd,       // Destination address
    input [31:0] Imm,     // Data to write (WriteData)
    output [31:0] RS1,    // Asynchronous output (Removed 'reg')
    output [31:0] RS2     // Asynchronous output (Removed 'reg')
    );
    
    reg [31:0] RB [0:31];
    integer i;

    // 1. ASYNCHRONOUS READ (Combinational)
    // We only output data if RB_E is HIGH.
    // If RB_E is low, we output 0.
    // We also enforce the R0 rule (if rs/rt == 0, output 0).
    assign RS1 = (RB_E == 1'b1) ? ((rs == 5'd0) ? 32'd0 : RB[rs]) : 32'd0;
    assign RS2 = (RB_E == 1'b1) ? ((rt == 5'd0) ? 32'd0 : RB[rt]) : 32'd0;

    // 2. SYNCHRONOUS WRITE (Sequential)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all registers to 0
            for(i = 0; i < 32; i = i + 1) begin
                RB[i] <= 32'b0;
            end
        end else begin
            // Write data ONLY if RB_W is high, RB_E is high, AND destination is NOT R0
            if (RB_W == 1'b1 && RB_E == 1'b1 && rd != 5'd0) begin
                RB[rd] <= Imm;
            end
        end
    end
endmodule