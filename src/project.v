/*
 * Copyright (c) 2024 Ruwan Kadam
 * SPDX-License-Identifier: Apache-2.0
 */

`timescale 1ns/1ps
`default_nettype none
module tt_um_UWASIC_onboarding_Ruwan_Kadam (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

`ifndef SYNTHESIS
initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tt_um_UWASIC_onboarding_Ruwan_Kadam);
end
`endif

  wire pwm_out = uo_out[0]; //wire added for testing purposes to observe uo_out[0] on a dedicated output pin
  assign uio_oe = 8'hFF; // Set all IOs to output

  reg [7:0] en_reg_out_7_0;
  reg [7:0] en_reg_out_15_8;
  reg [7:0] en_reg_pwm_7_0;
  reg [7:0] en_reg_pwm_15_8;
  reg [7:0] pwm_duty_cycle;

  wire [15:0] datahold;
  wire transaction_complete;

  SPIperipheral instSPI (.SCLK(ui_in[0]), .nCS(ui_in[2]), .COPI(ui_in[1]), .clk(clk), .rst_n(rst_n), .bitsend(datahold), .transaction_validated(transaction_complete));

always @(posedge clk) begin
    if (!rst_n) begin
        en_reg_out_7_0  <= 8'h00;
        en_reg_out_15_8 <= 8'h00;
        en_reg_pwm_7_0  <= 8'h00;
        en_reg_pwm_15_8 <= 8'h00;
        pwm_duty_cycle  <= 8'h00;
    end
    else if (transaction_complete && datahold[15]) begin //checking for only write bits in datahold[15]
        case (datahold[14:8])
            7'h00: en_reg_out_7_0  <= datahold[7:0];
            7'h01: en_reg_out_15_8 <= datahold[7:0];
            7'h02: en_reg_pwm_7_0  <= datahold[7:0];
            7'h03: en_reg_pwm_15_8 <= datahold[7:0];
            7'h04: pwm_duty_cycle  <= datahold[7:0];
            default: ;
        endcase
    end
end


  // Instantiate the PWM module
  pwm_peripheral pwm_peripheral_inst (
    .clk(clk),
    .rst_n(rst_n),
    .en_reg_out_7_0(en_reg_out_7_0),
    .en_reg_out_15_8(en_reg_out_15_8),
    .en_reg_pwm_7_0(en_reg_pwm_7_0),
    .en_reg_pwm_15_8(en_reg_pwm_15_8),
    .pwm_duty_cycle(pwm_duty_cycle),
    .out({uio_out, uo_out})
  );

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in[7:3], uio_in, 1'b0};
endmodule