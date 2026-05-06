

wire SCLK, nCS, COPI;
  assign SCLK = ui_in[0];
  assign nCS = ui_in[2];
  assign COPI = ui_in[1];

  reg [15:0]COPIsync_1, [15:0]COPIsync_2;

integer i = 0;
if 
 always @(posedge SCLK) begin
    if (~nCS) begin
      i = 
    
  end
 end
//_________________________________________________________________________________
// Process SPI protocol in the clk domain, rst_n is low to reset
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // omitted code
        transaction_ready <= 1'b0;
        // omitted code
    end else if (nCS_sync2 == 1'b0) begin
        // omitted code
    end else begin
        // When nCS goes high (transaction ends), validate the complete transaction
        if (nCS_posedge) begin
            transaction_ready <= 1'b1;
        end else if (transaction_processed) begin
            // Clear ready flag once processed
            transaction_ready <= 1'b0;
        end
        // omitted code
    end
end

// Update registers only after the complete transaction has finished and been validated
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // omitted code
        transaction_processed <= 1'b0;
    end else if (transaction_ready && !transaction_processed) begin
        // Transaction is ready and not yet processed
        // omitted code
        // Set the processed flag
        transaction_processed <= 1'b1;
    end else if (!transaction_ready && transaction_processed) begin
        // Reset processed flag when ready flag is cleared
        transaction_processed <= 1'b0;
    end
end