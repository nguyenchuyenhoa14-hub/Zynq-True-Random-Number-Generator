`timescale 1ns/1ps

(* KEEP_HIERARCHY = "TRUE" *)
(* DONT_TOUCH = "TRUE" *)
module ro_cell #(
    parameter STAGES = 3
)(
    input wire en, //enalbe signal
    output wire osc_out
);

    (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *) wire [STAGES:0] w;

    assign w[0] = en ? w[STAGES] : 1'b0; //en=0->stay, en=1->dao bit lien tuc

    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : gen_inverters
            (* KEEP = "TRUE", DONT_TOUCH = "TRUE" *) assign w[i+1] = ~w[i];
        end
    endgenerate

    assign osc_out = w[STAGES];

endmodule