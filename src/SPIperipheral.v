module SPIperipheral (
    input SCLK, nCS, COPI,
    input clk, rst_n,
    output reg [15:0]bitsend,//process output in top module
    output reg transaction_validated
);


//declaring registers
reg COPI_sync1, COPI_sync2;
reg nCS_sync1, nCS_sync2, nCS_prev3;
reg SCLK_sync1, SCLK_sync2, SCLK_prev3;
reg [15:0]bitstore;
reg transaction_ready;
reg transaction_processed;
reg c_ntinue;
reg [4:0] i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        nCS_sync1 <= 1'b1; 
        nCS_sync2 <= 1'b1;
        nCS_prev3 <= 1'b1;
    end else begin
        nCS_sync1  <= nCS;
        nCS_sync2  <= nCS_sync1;
        nCS_prev3  <= nCS_sync2;
        SCLK_sync1 <= SCLK;
        SCLK_sync2 <= SCLK_sync1;
        SCLK_prev3 <= SCLK_sync2;
        COPI_sync1 <= COPI;
        COPI_sync2 <= COPI_sync1;
    end
end

// Process SPI protocol in the clk domain
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        //What if rst_n is hit and resets the COPI_sync registers to zero while data is still being pushed into them?
        //The registers would then be half-filled, which would result in an incorrect address and/or message.
        //Hence, the c_ntinue protocol ensures registers are not filled in after a reset is hit.
        c_ntinue <= 1'b1;
        i <= 0;
        bitstore <= 16'b0;
        transaction_ready <= 1'b0;
    end
    else if ((nCS_sync2 == 1'b0)&&(c_ntinue == 1'b1)) begin //ensure nCS is low
        if ((SCLK_sync2 && !SCLK_prev3)&( i < 16)) begin
            bitstore[15-i] <= COPI_sync2; //bitstore [15-i] will never go out of bounds since i < 16.
            i <= i + 1;
        end
    end
    else begin
        // When nCS goes high (transaction ends), validate the complete transaction
        if (nCS_sync2 && !nCS_prev3) begin
            transaction_ready <= 1'b1;
            c_ntinue <= 1'b1;
        end
        else if (transaction_processed) begin
            transaction_ready <= 1'b0;
            bitstore[15:0] <= 16'b0;
            i <= 0;
        end
    end
end

// Update registers only after the complete transaction has finished and been validated
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        transaction_processed <= 1'b0;
        transaction_validated <= 1'b0;
        bitsend <= 16'b0;
    end else if (transaction_ready && !transaction_processed) begin
        // Transaction is ready and not yet processed
        bitsend[15:0] <= bitstore[15:0];
        transaction_validated <= 1'b1; // Validation allows the values in bitsend to be read by top module.
        transaction_processed <= 1'b1;
    end else begin
        transaction_validated <= 1'b0;
        if (!transaction_ready && transaction_processed) begin
        // Reset processed flag when ready flag is cleared
        transaction_processed <= 1'b0;
    end
    end
end


endmodule