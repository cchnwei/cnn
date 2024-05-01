`timescale 1ns/10ps

module  CONV(
  input				clk,
  input				reset,
  output logic		busy,	
  input				ready,	
  //gray-image mem
  output logic [13:0]	iaddr,
  input  		 [7:0]	idata,	
  output logic		ioe,
  //L0 mem
  output logic		wen_L0,
  output logic		oe_L0,
  output logic [13:0]	addr_L0,
  output logic [11:0] w_data_L0,
  input  		 [11:0] r_data_L0,
  //L1 mem
  output logic 		wen_L1,
  output logic		oe_L1,
  output logic [11:0]	addr_L1,
  output logic [11:0]	w_data_L1,
  input  		 [11:0]	r_data_L1,
  //weight mem
  output logic		oe_weight,
  output logic [15:0]	addr_weight,
  input  logic signed  [7:0]  r_data_weight,
  //L2 mem
  output logic		wen_L2,
  output logic [3:0]	addr_L2,
  output logic [31:0]	w_data_L2
  );

//you can only motify your code below

  // layer0 fsm
  localparam INITIAL0 = 0;
  localparam READ0    = 1;
  localparam EXECUTE0 = 2;
  localparam WRITE0   = 3;
  localparam DONE0    = 4;
  //

  // layer1 fsm
  localparam EXECUTE1 = 0;
  localparam IDLE10   = 1;
  localparam WRITE1   = 2;
  localparam IDLE11   = 3;
  localparam DONE1    = 4;
  //

  // layer2 fsm
  localparam INITIAL2 = 0;
  localparam IDLE20   = 1;
  localparam IDLE21   = 2;
  localparam READ2    = 3;
  localparam IDLE22   = 4;
  localparam IDLE23   = 5;
  localparam IDLE24   = 6;
  localparam IDLE25   = 7;
  localparam WRITE2   = 8;
  //

  // define reg or wire
  reg  [2:0]  layer0_cs;
  reg  [2:0]  layer0_ns;
  reg  [2:0]  layer1_cs;
  reg  [2:0]  layer1_ns;
  reg  [3:0]  layer2_cs;
  reg  [3:0]  layer2_ns;
  reg  [7:0]  column0_cnt;
  reg  [7:0]  column1_cnt;
  reg  [7:0]  row0_cnt;
  reg  [12:0] AfterFilter [0:8];
  reg  [7:0]  weight; 
  reg  [11:0] flatten;
  wire read0_done;
  wire read2_done;
  wire execute0_done;
  wire execute1_done;
  wire write0_done;
  wire write1_done;
  wire sr1_en;
  wire sr2_en;
  wire idle;
  //

  // logic
  assign read0_done = (iaddr==14'd130);
  assign read2_done = (addr_L1==4095);
  assign execute0_done = (iaddr==14'd133);
  assign execute1_done = (addr_L0==14'd129);
  assign write0_done = (addr_L0==16383);
  assign write1_done = (addr_L1==4095);
  assign sr1_en = (layer0_cs>=READ0);
  assign sr2_en = (layer1_cs>=EXECUTE1);
  assign idle = (column1_cnt>=126 && column1_cnt<255);
  //

  // layer0 fsm state transition
  always @(posedge clk, posedge reset) begin
    if (reset) layer0_cs <= INITIAL0;
    else       layer0_cs <= layer0_ns;
  end

  always @(*) begin
    layer0_ns=3'bx;
    case (layer0_cs)
      INITIAL0:
        begin
          if (ready)          layer0_ns=READ0;
          else                layer0_ns=INITIAL0;  // loopback
        end 
      READ0: 
        begin 
          if (read0_done)     layer0_ns=EXECUTE0;
          else                layer0_ns=READ0;    // loopback
        end 
      EXECUTE0: 
        begin 
          if (execute0_done)  layer0_ns=WRITE0;
          else                layer0_ns=EXECUTE0; // loopback
        end  
      WRITE0: 
        begin 
          if (write0_done)    layer0_ns=DONE0;
          else                layer0_ns=WRITE0;   // loopback
        end
      DONE0:
        begin
                              layer0_ns=DONE0;    // loopback
        end
    endcase
  end
  //

  // layer0 control signal
  always @(*) begin
    ioe=1;
    case (layer0_cs)
      INITIAL0:
        begin

        end
      READ0:
        begin

        end
      EXECUTE0:
        begin

        end
      WRITE0:
        begin

        end
      DONE0:
        begin
          
        end
    endcase
  end
  //

  // layer0 write enable
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      wen_L0<=0;
    end else begin
      if (layer0_ns==WRITE0) begin
        wen_L0<=1;
      end else begin
        wen_L0<=0;
      end
    end
  end
  //

  // layer1 fsm state transition
  always @(posedge clk, posedge reset) begin
    if (reset) layer1_cs <= EXECUTE1;
    else       layer1_cs <= layer1_ns;
  end

  always @(*) begin
    layer1_ns=2'bx;
    case (layer1_cs)
      EXECUTE1:
        begin
          if (execute1_done)  layer1_ns=IDLE10;
          else                layer1_ns=EXECUTE1; // loopback
        end
      IDLE10:
        begin
                              layer1_ns=WRITE1;
        end
      WRITE1:
        begin
          if (write1_done)    layer1_ns=DONE1;
          else                layer1_ns=IDLE11;
        end
      IDLE11:
        begin
          if (idle)           layer1_ns=IDLE11;   // loopback
          else                layer1_ns=WRITE1;
        end
      DONE1:
        begin
                              layer1_ns=DONE1;    // loopback
        end
    endcase
  end
  //

  // layer1 write enable
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      wen_L1<=0;
    end else begin
      if (layer1_ns==WRITE1) begin
        wen_L1<=1;
      end else begin
        wen_L1<=0;
      end
    end
  end
  //

  // layer2 fsm state transition
  always @(posedge clk, posedge reset) begin
    if (reset) layer2_cs <= INITIAL2;
    else       layer2_cs <= layer2_ns;
  end

  always @(*) begin
    layer2_ns=4'bx;
    case (layer2_cs)
      INITIAL2:
        begin
          if (layer1_cs==DONE1) layer2_ns=IDLE20;
          else                  layer2_ns=INITIAL2; // loopback
        end
      IDLE20:
        begin
                                layer2_ns=IDLE21; 
        end      
      IDLE21:      
        begin      
                                layer2_ns=READ2;   
        end
      READ2:
        begin
          if (read2_done)       layer2_ns=IDLE22;
          else                  layer2_ns=READ2;    // loopback
        end
      IDLE22:
        begin
                                layer2_ns=IDLE23;
        end
      IDLE23:
        begin
                                layer2_ns=IDLE24;   
        end
      IDLE24:
        begin
                                layer2_ns=IDLE25;   
        end
      IDLE25: // rst fc_scc 
        begin
                                layer2_ns=WRITE2;   
        end
      WRITE2:     
        begin      
                                layer2_ns=READ2;   
        end
    endcase
  end
  //

  // layer2 control signal
  always @(*) begin
    wen_L2=0;
    oe_weight=1;
    oe_L1=0;
    case (layer2_cs)
      INITIAL2:
        begin

        end
      IDLE20:
        begin
          oe_L1=1;
        end
      IDLE21:
        begin
          oe_L1=1;
        end
      READ2:
        begin
          oe_L1=1;
        end
      IDLE22:
        begin
          oe_L1=1;
        end
      IDLE23:
        begin
          oe_L1=1;
        end
      IDLE24:
        begin
          oe_L1=1;
        end
      IDLE25: // rst fc_scc 
        begin
          oe_L1=1;
        end
      WRITE2: 
        begin
          wen_L2=1;
          oe_L1=1;
        end
    endcase
  end
  //

  // grayscale addr
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      iaddr <= 0;
    end else begin
      iaddr <= iaddr+1;
    end
  end
  //

  // layer0 column counter
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      column0_cnt <= 0;
    end else begin
      if (layer0_cs>=EXECUTE0) begin
        if (column0_cnt!=127 && ioe) begin
          column0_cnt <= column0_cnt+1;
        end else if (column0_cnt==127 && ioe) begin
          column0_cnt <= 0;
        end
      end
    end
  end
  //

  // layer0 row counter
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      row0_cnt <= 0;
    end else begin
      if (layer0_cs>=EXECUTE0) begin
        if (column0_cnt!=127 && ioe) begin
          row0_cnt <= row0_cnt;
        end else if (column0_cnt==127 && ioe) begin
          row0_cnt <= row0_cnt+1;
        end
      end
    end
  end
  //

  // layer1 column counter
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      column1_cnt <= 0;
    end else begin
      if (layer1_cs>=WRITE1) begin
        if (column1_cnt!=255) begin
          column1_cnt <= column1_cnt+1;
        end else if (column1_cnt==255) begin
          column1_cnt <= 0;
        end
      end
    end
  end
  //

  // sr_8x259
  wire [7:0] p0;
  wire [7:0] p1;
  wire [7:0] p2;
  wire [7:0] p3;
  wire [7:0] p4;
  wire [7:0] p5;
  wire [7:0] p6;
  wire [7:0] p7;
  wire [7:0] p8;
  wire [8:0] p0_shf;
  wire [8:0] p5_shf;
  wire [8:0] p7_shf;
  wire [8:0] p8_shf;
  assign p0_shf = p0<<1;
  assign p5_shf = p5<<1;
  assign p7_shf = p7<<1;
  assign p8_shf = p8<<1;

  sr_8x259 sr1 (
    .clk(clk),
    .en(sr1_en),
    .sr_in(idata),
    .sr_tap1(p0),
    .sr_tap2(p1),
    .sr_tap3(p2),
    .sr_tap4(p3),
    .sr_tap5(p4),
    .sr_tap6(p5),
    .sr_tap7(p6),
    .sr_tap8(p7),
    .sr_tap9(p8)
  );
  //

  // conv-filter
  always @(*) begin
    AfterFilter[0] =  - (p0_shf)       ;
    AfterFilter[1] =     0             ;
    AfterFilter[2] =     p2            ;
    AfterFilter[3] =     0             ;
    AfterFilter[4] =     p4            ;
    AfterFilter[5] =     p5_shf        ;
    AfterFilter[6] =     p6            ;
    AfterFilter[7] =     p7_shf        ;
    AfterFilter[8] =  -((p8_shf)+p8)   ;

    if (row0_cnt==0) begin
      AfterFilter[0] = 0;
      AfterFilter[1] = 0;
      AfterFilter[2] = 0;
    end

    if (column0_cnt==0) begin
      AfterFilter[0] = 0;
      AfterFilter[3] = 0;
      AfterFilter[6] = 0;
    end 

    if (column0_cnt==127) begin
      AfterFilter[2] = 0;
      AfterFilter[5] = 0;
      AfterFilter[8] = 0;
    end 

    if (row0_cnt==127) begin
      AfterFilter[6] = 0;
      AfterFilter[7] = 0;
      AfterFilter[8] = 0;
    end 
  end

  // conv-pipeline stage0
  wire [12:0] add0_0;
  wire [12:0] add1_0;
  wire [12:0] add2_0;
  wire [12:0] add3_0;
  reg  [12:0] add0;
  reg  [12:0] add1;
  reg  [12:0] add2;
  reg  [12:0] add3;
  assign add0_0 = AfterFilter[0]+AfterFilter[2];
  assign add1_0 = AfterFilter[4]+AfterFilter[5];
  assign add2_0 = AfterFilter[6]+AfterFilter[7];
  assign add3_0 = AfterFilter[8];

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      add0 <= 0; 
      add1 <= 0;
      add2 <= 0;
      add3 <= 0;
    end else begin
      add0 <= add0_0; 
      add1 <= add1_0;
      add2 <= add2_0;
      add3 <= add3_0;
    end
  end
  //

  // conv-pipeline stage1
  wire [12:0] add4_1;
  wire [12:0] add5_1;
  reg  [12:0] add4;
  reg  [12:0] add5;
  assign add4_1 = add0+add1;
  assign add5_1 = add2+add3;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      add4 <= 0;
      add5 <= 0;
    end else begin
      add4 <= add4_1;
      add5 <= add5_1;
    end
  end
  //

  // conv-pipeline stage2
  wire [12:0] add6_2;
  assign add6_2 = add4+add5;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      w_data_L0 <= 0;
    end else begin
      if (add6_2[12]) begin
        w_data_L0 <= 0;
      end else begin
        w_data_L0 <= add6_2;
      end
    end
  end

  // L0 RAM address
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      addr_L0 <= 0;
    end else begin
      if (wen_L0) begin
        addr_L0 <= addr_L0+1;
      end
    end
  end
  //

  // sr_12x130
  wire [11:0] reg0;
  wire [11:0] reg1;

  sr_12x130 sr2 (
    .clk(clk),
    .en(sr2_en),
    .sr_in(w_data_L0),
    .sr_tap1(reg0),
    .sr_tap2(reg1)
  );
  //

  // maxpooling
  reg [11:0] max_temp;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      max_temp <= 0;
    end else begin
      if (reg0>=reg1) begin
        max_temp <= reg0;
      end else begin
        max_temp <= reg1;
      end
    end
  end

  // write data to L1 RAM
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      w_data_L1 <= 0;
    end else begin
      if (max_temp>= reg0 && max_temp>= reg1) begin
        w_data_L1 <= max_temp;
      end else if (reg0>= max_temp && reg0>= reg1) begin
        w_data_L1 <= reg0;
      end else begin
        w_data_L1 <= reg1;
      end
    end
  end
  //

  // L1 RAM address
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      addr_L1 <= 0;
    end else begin
      if (wen_L1||layer1_cs==DONE1) begin
        addr_L1 <= addr_L1+1;
      end
    end
  end
  //

  // address weight
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      addr_weight <= 0;
    end else begin
      if (layer1_cs==DONE1) begin
        addr_weight <= addr_weight+1;
      end
    end
  end
  //

  // read data from weight_RAM, L1_RAM
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      weight <= 0;
      flatten <= 0;
    end else begin
      weight <= r_data_weight;
      flatten <= r_data_L1;
    end
  end
  //

  // fully connected
  wire [20:0] fc0;
  reg [20:0] fc;

  mul FC (
    .in1(weight),
    .in2({1'b0,flatten}),
    .out(fc0)
  );
  //

  // 
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      fc <= 0;
    end else begin
      fc <= fc0;
    end
  end
  //

  // fc_acc
  reg  [31:0] fc_acc;
  wire [31:0] fc_sum0;
  wire [31:0] signed_fc;
  wire [31:0] signed_fc_acc;

  // fc_sum0 = $signed(fc_acc) + $signed(fc) rst
  assign signed_fc = $signed(fc);
  assign signed_fc_acc = $signed(fc_acc);

  CLA32 cla (
    .a(signed_fc),
    .b(signed_fc_acc),
    .cin(1'b0),
    .out(fc_sum0)
  );
  //

  // accumulator
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      fc_acc <= 0;
    end else begin 
      if (layer2_cs==IDLE24) begin
        fc_acc <= 0;
      end else begin
        if ((layer2_cs==READ2||layer2_cs==IDLE20||layer2_cs==IDLE21||layer2_cs==IDLE22||layer2_cs==IDLE23||layer2_cs==IDLE25||layer2_cs==WRITE2) && addr_L1!=2) begin
          fc_acc <= fc_sum0;
        end
      end
    end
  end
  //

  //
  reg [31:0] fc_sum;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      fc_sum <= 0;
    end else begin
      fc_sum <= fc_sum0;
    end
  end
  //

  // leaky relu
  reg [31:0] w_data_L2_reg;
  wire [15:0] fc_sum_shf;
  assign fc_sum_shf = fc_sum>>16;

  always @(*) begin
    if (fc_sum[31]==1) begin
      w_data_L2_reg = $signed(fc_sum_shf);
    end else begin
      w_data_L2_reg = fc_sum;
    end
  end
  //

  //
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      w_data_L2 <= 0;
    end else begin
      if (layer2_cs==INITIAL2) begin
        w_data_L2 <= 0;
      end else begin
        w_data_L2 <= w_data_L2_reg;
      end
    end       
  end
  //

  // L2 RAM address
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      addr_L2 <= 0;
    end else begin
      if (wen_L2) begin
        addr_L2 <= addr_L2+1;
      end
    end
  end
  //

  // busy
  always @(posedge clk, posedge reset) begin
    if (reset) begin
      busy <= 0;
    end else begin
      case (addr_weight)
        40963: busy <= 1;
        40964: busy <= 0;
      endcase
    end
  end
  //

endmodule

module CLA32 (
  // input port
  input [31:0] a,
  input [31:0] b,
  input        cin,
  // output port
  output [32:0] out
);

  wire cout0;
  wire cout1;
  wire cout2;

  //
  CLA8 cla0 (.a(a[7:0]),   .b(b[7:0]),   .cin(cin),   .sum(out[7:0]),   .cout(cout0)   );
  CLA8 cla1 (.a(a[15:8]),  .b(b[15:8]),  .cin(cout0), .sum(out[15:8]),  .cout(cout1)   );
  CLA8 cla2 (.a(a[23:16]), .b(b[23:16]), .cin(cout1), .sum(out[23:16]), .cout(cout2)   );
  CLA8 cla3 (.a(a[31:24]), .b(b[31:24]), .cin(cout2), .sum(out[31:24]), .cout(out[32]) );
  //
  
endmodule

module CLA8 (
  // input port
  input [7:0] a,
  input [7:0] b,
  input       cin,
  // output port
  // output [8:0] out
  output [7:0] sum,
  output       cout
);

  wire [7:0] p;
  wire [7:0] g;
  wire [6:0] c; // CLA_FA　carry in

  //
  CLG clg8 (
    .cin(cin),
    .p(p),
    .g(g),
    .cout({cout, c[6:0]})
  );
  //

  //
  CLA_FA cla_fa0 (.a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .g(g[0]), .p(p[0]));
  //

  //
  genvar i;

  generate
  for (i=1;i<8;i=i+1) begin:cla_fa
    CLA_FA cla_fa (.a(a[i]), .b(b[i]), .cin(c[i-1]), .sum(sum[i]), .g(g[i]), .p(p[i]));
  end
  endgenerate
  //
  
endmodule

module CLG (
  // input port
  input cin,
  input [7:0] p,
  input [7:0] g,
  // output port
  output [7:0] cout
);

  assign cout[0] = (cin & p[0])                                                  | (g[0])                                                                                                                                                                                                                                                                     ;
  assign cout[1] = (cin & p[0] & p[1])                                           | (g[0] & p[1])                                           | (g[1])                                                                                                                                                                                                           ;
  assign cout[2] = (cin & p[0] & p[1] & p[2])                                    | (g[0] & p[1] & p[2])                                    | (g[1] & p[2])                                    | (g[2])                                                                                                                                                        ;
  assign cout[3] = (cin & p[0] & p[1] & p[2] & p[3])                             | (g[0] & p[1] & p[2] & p[3])                             | (g[1] & p[2] & p[3])                             | (g[2] & p[3])                             | (g[3] )                                                                                                           ;
  assign cout[4] = (cin & p[0] & p[1] & p[2] & p[3] & p[4])                      | (g[0] & p[1] & p[2] & p[3] & p[4])                      | (g[1] & p[2] & p[3] & p[4])                      | (g[2] & p[3] & p[4])                      | (g[3] & p[4])                      | (g[4])                                                                       ;
  assign cout[5] = (cin & p[0] & p[1] & p[2] & p[3] & p[4] & p[5])               | (g[0] & p[1] & p[2] & p[3] & p[4] & p[5])               | (g[1] & p[2] & p[3] & p[4] & p[5])               | (g[2] & p[3] & p[4] & p[5])               | (g[3] & p[4] & p[5])               | (g[4] & p[5])               | (g[5])                                         ;
  assign cout[6] = (cin & p[0] & p[1] & p[2] & p[3] & p[4] & p[5] & p[6])        | (g[0] & p[1] & p[2] & p[3] & p[4] & p[5] & p[6])        | (g[1] & p[2] & p[3] & p[4] & p[5] & p[6])        | (g[2] & p[3] & p[4] & p[5] & p[6])        | (g[3] & p[4] & p[5] & p[6])        | (g[4] & p[5] & p[6])        | (g[5] & p[6])         | (g[6])                 ;
  assign cout[7] = (cin & p[0] & p[1] & p[2] & p[3] & p[4] & p[5] & p[6] & p[7]) | (g[0] & p[1] & p[2] & p[3] & p[4] & p[5] & p[6] & p[7]) | (g[1] & p[2] & p[3] & p[4] & p[5] & p[6] & p[7]) | (g[2] & p[3] & p[4] & p[5] & p[6] & p[7]) | (g[3] & p[4] & p[5] & p[6] & p[7]) | (g[4] & p[5] & p[6] & p[7]) | (g[5] & p[6] & p[7])  | (g[6] & p[7]) | (g[7]) ;
  
endmodule

module CLA_FA ( // without carry out
  // input port
  input a,
  input b,
  input cin,
  // output port
  output sum,
  output p,
  output g
);

  assign sum = a^b^cin;
  assign p   = a|b;
  assign g   = a&b;
  
endmodule

module mul (
  // input port
  input  [7:0]  in1, // 8-bit, signed integer
  input  [12:0] in2, // 13-bit, unsigned integer
  // output port
  output reg [20:0] out // 21-bit
);

  // define reg or wire
  reg [20:0] add0;
  reg [18:0] add1;
  reg [16:0] add2;
  reg [14:0] add3;
  reg [12:0] add4;
  reg [10:0] add5;
  reg [8:0]  add6;
  // 

  // booth encoding
  always @(*) begin
    add0=0;
    case ({in2[1:0],1'b0})
      3'b000, 3'b111 : add0 =  0; 
      3'b001, 3'b010 : add0 = $signed( in1); 
      3'b101, 3'b110 : add0 = $signed(-in1); 
      3'b011         : add0 = $signed( (in1<<1)); 
      3'b100         : add0 = $signed(-(in1<<1)); 
    endcase
  end

  always @(*) begin
    add1=0;
    case (in2[3:1])
      3'b000, 3'b111 : add1 =  0; 
      3'b001, 3'b010 : add1 = $signed( in1); 
      3'b101, 3'b110 : add1 = $signed(-in1); 
      3'b011         : add1 = $signed( (in1<<1)); 
      3'b100         : add1 = $signed(-(in1<<1)); 
    endcase
  end

  always @(*) begin
    add2=0;
    case (in2[5:3])
      3'b000, 3'b111 : add2 =  0; 
      3'b001, 3'b010 : add2 = $signed( in1); 
      3'b101, 3'b110 : add2 = $signed(-in1); 
      3'b011         : add2 = $signed( (in1<<1)); 
      3'b100         : add2 = $signed(-(in1<<1)); 
    endcase
  end

  always @(*) begin
    add3=0;
    case (in2[7:5])
      3'b000, 3'b111 : add3 =  0; 
      3'b001, 3'b010 : add3 = $signed( in1); 
      3'b101, 3'b110 : add3 = $signed(-in1); 
      3'b011         : add3 = $signed( (in1<<1)); 
      3'b100         : add3 = $signed(-(in1<<1)); 
    endcase
  end

  always @(*) begin
    add4=0;
    case (in2[9:7])
      3'b000, 3'b111 : add4 =  0; 
      3'b001, 3'b010 : add4 = $signed( in1); 
      3'b101, 3'b110 : add4 = $signed(-in1); 
      3'b011         : add4 = $signed( (in1<<1)); 
      3'b100         : add4 = $signed(-(in1<<1)); 
    endcase
  end

  always @(*) begin
    add5=0;
    case (in2[11:9])
      3'b000, 3'b111 : add5 =  0; 
      3'b001, 3'b010 : add5 = $signed( in1); 
      3'b101, 3'b110 : add5 = $signed(-in1); 
      3'b011         : add5 = $signed( (in1<<1)); 
      3'b100         : add5 = $signed(-(in1<<1)); 
    endcase
  end

  always @(*) begin
    add6=0;
    case ({in2[12],in2[12:11]})
      3'b000, 3'b111 : add6 =  0; 
      3'b001, 3'b010 : add6 = $signed( in1); 
      3'b101, 3'b110 : add6 = $signed(-in1); 
      3'b011         : add6 = $signed( (in1<<1)); 
      3'b100         : add6 = $signed(-(in1<<1)); 
    endcase
  end
  //

  // wallace tree
  wire [20:0] sum0;
  wire [20:0] carry0;
  wire [20:0] carry0_shf;
  assign carry0_shf = carry0<<1;

  adder21 adder21_0 (
    .a(add0),
    .b({add1,2'b0}),
    .cin({add2,4'b0}),
    .sum(sum0),
    .cout(carry0)
  );
  //

  //
  wire [20:0] sum1;
  wire [20:0] carry1;
  wire [20:0] carry1_shf;
  assign carry1_shf = carry1<<1;

  adder21 adder21_1 (
    .a({add3,6'b0}),
    .b({add4,8'b0}),
    .cin({add5,10'b0}),
    .sum(sum1),
    .cout(carry1)
  );
  //

  //
  wire [20:0] sum2;
  wire [20:0] carry2;
  wire [20:0] carry2_shf;
  assign carry2_shf = carry2<<1;

  adder21 adder21_2 (
    .a(sum0),
    .b(carry0_shf),
    .cin(sum1),
    .sum(sum2),
    .cout(carry2)
  );
  //

  //
  wire [20:0] sum3;
  wire [20:0] carry3;
  wire [20:0] carry3_shf;
  assign carry3_shf = carry3<<1;

  adder21 adder21_3 (
    .a(carry1_shf),
    .b(carry2_shf),
    .cin(sum2),
    .sum(sum3),
    .cout(carry3)
  );
  //

  //
  wire [20:0] sum4;
  wire [20:0] carry4;
  wire [20:0] carry4_shf;
  assign carry4_shf = carry4<<1;

  adder21 adder21_4 (
    .a(carry3_shf),
    .b(sum3),
    .cin({add6,12'b0}),
    .sum(sum4),
    .cout(carry4)
  );
  //

  // out = sum4 + carry4
  reg [11:0] out_temp0; // msb is carry-bit
  reg [10:0] out_temp1;
  reg [10:0] out_temp2;

  always @(*) begin
    out_temp0 = sum4[10:0]+carry4_shf[10:0]; 
  end

  always @(*) begin
    out_temp1 = sum4[20:11]+carry4_shf[20:11]+1; // carry is 1
    out_temp2 = sum4[20:11]+carry4_shf[20:11];   // carry is 0
  end

  always @(*) begin
    if (out_temp0[11]) begin // carry is 1
      out = {out_temp1, out_temp0[10:0]};
    end else begin           // carry is 0
      out = {out_temp2, out_temp0[10:0]};
    end
  end
  //
  
endmodule

module adder21 (
  input [20:0] a,
  input [20:0] b,
  input [20:0] cin,
  output [20:0] sum,
  output [20:0] cout
);

  genvar i;

  generate
    for (i=0;i<21;i=i+1) begin:FA
      FA fa (.a(a[i]), .b(b[i]), .cin(cin[i]), .sum(sum[i]), .cout(cout[i]));
    end
  endgenerate
  
endmodule

module FA (
  input a, 
  input b,
  input cin,
  output sum, 
  output cout 
);

  wire c1, c2, s1;

  HA ha1(.a(a), .b(b), .cout(c1), .sum(s1));
  HA ha2(.a(s1), .b(cin), .cout(c2), .sum(sum));
  or (cout, c1, c2);
endmodule

module HA (
  input a, 
  input b,
  output sum, 
  output cout 
);

  xor (sum, a, b);
  and (cout, a, b);
endmodule

module sr_8x259 (
  input clk,
  input en,
  input  [7:0] sr_in,
  output [7:0] sr_tap1,
  output [7:0] sr_tap2,
  output [7:0] sr_tap3,
  output [7:0] sr_tap4,
  output [7:0] sr_tap5,
  output [7:0] sr_tap6,
  output [7:0] sr_tap7, 
  output [7:0] sr_tap8, 
  output [7:0] sr_tap9 
);

  reg [7:0] sr [0:258];

  integer i;

  always @(posedge clk) begin
    if (en) begin
      sr[258] <= sr_in;
      for (i=0;i<258;i=i+1) begin
        sr[i] <= sr[i+1];
      end
    end
  end

  assign sr_tap1 = sr[0];
  assign sr_tap2 = sr[1];
  assign sr_tap3 = sr[2];
  assign sr_tap4 = sr[128];
  assign sr_tap5 = sr[129];
  assign sr_tap6 = sr[130];
  assign sr_tap7 = sr[256];
  assign sr_tap8 = sr[257];
  assign sr_tap9 = sr[258];
  
endmodule

module sr_12x130 (
  input clk,
  input en,
  input  [11:0] sr_in,
  output [11:0] sr_tap1,
  output [11:0] sr_tap2
);

  reg [11:0] sr [0:129];

  integer i;

  always @(posedge clk) begin
    if (en) begin
      sr[129] <= sr_in;
      for (i=0;i<129;i=i+1) begin
        sr[i] <= sr[i+1];
      end
    end
  end

  assign sr_tap1 = sr[1];
  assign sr_tap2 = sr[129];
  
endmodule