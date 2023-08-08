`define LRU 1
`ifdef LRU
    `define MAX_AGE 32'h7fffffff
`endif 

module DataCache #(
    parameter LINE_ADDR_LEN = 3, // Each cache line has 2^LINE_ADDR_LEN words
    parameter SET_ADDR_LEN = 3, // This cache has 2^SET_ADDR_LEN cache sets
    parameter TAG_ADDR_LEN = 10, // should in alignment with main memory's space
    parameter WAY_CNT = 16 // each cache set contains WAY_CNT cache lines
) (
    input clk, rst, debug,
    // ports between cache and CPU
    input read_request, write_request,
    input [2:0] write_type,
    input [31:0] addr, write_data,
    output reg request_finish,
    output reg [31:0] read_data,
    // ports between cache and main memory
    output mem_read_request, mem_write_request,
    output [(32*(1<<LINE_ADDR_LEN)-1):0] mem_write_data,
    output [31:0] mem_addr,
    input mem_request_finish,
    input [(32*(1<<LINE_ADDR_LEN)-1):0] mem_read_data,
    
    // interface between cache and accelerator
    input if_accelerator_read, if_accelerator_write,
    output reg [(32*(1<<LINE_ADDR_LEN)-1):0] accelerator_read_data, 
    input [(32*(1<<LINE_ADDR_LEN)-1):0] accelerator_write_data
);
    // params to transfer bit number to count
    localparam WORD_ADDR_LEN = 2; // each word contains 4 bytes
    localparam MEM_ADDR_LEN = TAG_ADDR_LEN + SET_ADDR_LEN; // in cache line's granularity
    localparam UNUSED_ADDR_LEN = 32 - MEM_ADDR_LEN - LINE_ADDR_LEN - WORD_ADDR_LEN;
    localparam LINE_SIZE = 1 << LINE_ADDR_LEN; // each cache line has LINE_SIZE words
    localparam SET_SIZE = 1 << SET_ADDR_LEN; // This cache has SET_SIZE cache sets
    localparam WAY_ADDR_LEN = 4;
    // cache state enumarations
    parameter [1:0] READY = 2'b00;
    parameter [1:0] REPLACE_OUT = 2'b01;
    parameter [1:0] REPLACE_IN = 2'b10;

    // cache units declaration
    reg [31:0]             cache_data [0:SET_SIZE-1][0:WAY_CNT-1][0:LINE_SIZE-1];
    reg [TAG_ADDR_LEN-1:0] tag [0:SET_SIZE-1][0:WAY_CNT-1];
    reg                    valid [0:SET_SIZE-1][0:WAY_CNT-1];
    reg                    dirty [0:SET_SIZE-1][0:WAY_CNT-1];

    // current cache state
    reg [1:0] cache_state;

    // can use the address to return the set address and target tag 
    wire [TAG_ADDR_LEN-1:0] target_tag;
    wire [SET_ADDR_LEN-1:0] set_addr;
    wire [LINE_ADDR_LEN-1:0] line_addr;

    // cache design exploration
    reg [31:0] miss;
    reg [31:0] hit_count;

    // cache state variable
    reg hit;
    reg [WAY_ADDR_LEN-1:0] return_way;

    // for replace policy, basically, we will implement FIFO policy
    // For simplicity, we can assign cache lines from way 0 to way WAY_CNT-1
    // In this way, FIFO is equivalant to round-robbin policy
    reg [WAY_ADDR_LEN-1:0] replace_way [0:SET_SIZE-1];
    // for LRU, we need to record the age of each way in each set, and the way with the biggest age
`ifdef LRU
    // record each way's age
    reg [31:0] way_age [0:SET_SIZE-1][0:WAY_CNT-1];
`endif

    // Used for memory read/write ports' unpack/pack
    reg [31:0] mem_write_line [0:LINE_SIZE-1];
    wire [31:0] mem_read_line [0:LINE_SIZE-1];
    genvar line;
    generate
        for(line=0; line<LINE_SIZE; line=line+1)
        begin : memory_interface
            assign mem_write_data[32*(LINE_SIZE-line)-1:32*(LINE_SIZE-line-1)] = mem_write_line[line];
            assign mem_read_line[line] = mem_read_data[32*(LINE_SIZE-line)-1:32*(LINE_SIZE-line-1)];
        end
    endgenerate

    // address translation
    // to translate the address from the CPU to the set address and the tag in cache
    assign {target_tag, set_addr, line_addr} = addr[31-UNUSED_ADDR_LEN : 2];


    // check whether current request hits cache line
    // if cache hits, record the way hit by this request
   
    integer w;
    always @(*) begin
        hit = 1'b0;
        return_way = {WAY_ADDR_LEN{1'b0}};
        for( w=0; w<WAY_CNT & hit == 1'b0; w=w+1)begin
            if(cache_state==READY & (read_request | write_request) & (tag[set_addr][w] == target_tag) & valid[set_addr][w])begin
                hit = 1'b1;
                return_way = w;
            end
        end
    end

`ifdef LRU
    // combination logic to choose the way with max age
    always @(*) begin
        
        for(w=WAY_CNT-1; w>=0; w=w-1)begin
            if(valid[set_addr][w])begin
                if(way_age[set_addr][w] >= way_age[set_addr][replace_way[set_addr]])begin
                    replace_way[set_addr] = w;
                end
            end
            else replace_way[set_addr] = w;
            
        end
    end
`endif


    // interact with memory interface when cache miss/replacement occurs

    // need to decide which of the cache line to be replaced.
    wire [31:0] mem_addr1 = (mem_read_request) ? {addr[31:LINE_ADDR_LEN+2],{LINE_ADDR_LEN{1'b0}},2'b0} : ((mem_write_request) ? 
    {{UNUSED_ADDR_LEN{1'b0}}, tag[set_addr][replace_way[set_addr]], set_addr, {LINE_ADDR_LEN{1'b0}}, 2'b0} : 32'b0);
    assign mem_addr[31:0] = mem_addr1 + `DATA_MEM_BASE_ADDR;
    assign mem_read_request = (cache_state == REPLACE_IN);
    assign mem_write_request = (cache_state == REPLACE_OUT);
    always @(*) begin
        if(mem_write_request)begin
            for(i=0; i<LINE_SIZE; i=i+1)begin
                mem_write_line[i] <= cache_data[set_addr][replace_way[set_addr]][i];
            end
        end
        
        if(mem_read_request)begin
            for(i=0; i<LINE_SIZE; i=i+1)begin
                cache_data[set_addr][replace_way[set_addr]][i] <= mem_read_line[i]; // to load the memory data into the replaced way of the cache
            end
            tag[set_addr][replace_way[set_addr]] <= target_tag;
            dirty[set_addr][replace_way[set_addr]] <= 1'b0;
        end
    end

    // deal with cacheline readout for accelerator
    wire  [(32*(1<<LINE_ADDR_LEN)-1):0] cacheline;
    genvar index;
    generate
        for(index=0; index<LINE_SIZE; index=index+1) begin
            assign cacheline[(LINE_SIZE-index)*32-1:(LINE_SIZE-1-index)*32] = cache_data[set_addr][return_way][index];
        end
    endgenerate

    // cache state machine update logic
    integer i, j, k;
    always @(posedge clk)
    begin
        if(rst)
        begin
            // init CPU-cache interfaces
            request_finish <= 1'b0;
            read_data <= 32'h00000000;
            accelerator_read_data <= 'b0;

            //clear exploration miss
            miss <= 32'b0;
            hit_count <= 32'b0;
            
            // init cache state
            cache_state <= READY;
            
            // init cache lines
            for(i=0; i<SET_SIZE; i=i+1)
            begin
                replace_way[i] <= 0;
                for(j=0; j<WAY_CNT; j=j+1)
                begin
                    valid[i][j] <= 1'b0;
                    dirty[i][j] <= 1'b0;
                    `ifdef LRU
                    way_age[i][j] <= `MAX_AGE;
                    `endif 
                end
            end
            
            // init cache-memory interfaces
            for(k=0; k<LINE_SIZE; k=k+1)
            begin
                mem_write_line[k] <= 32'h00000000;
            end
        end

        else
        begin
            case (cache_state)
                READY:
                begin
                    if(hit)
                    begin
                        // notify CPU whether the request can be finished
                        // when the former instruction completes, the next instrcution should not be 1, 
                        // that is, the request_finish signal cannot be 1 for two consecutive clk cycle
                        request_finish <=  ~request_finish & 1'b1;

                        // update cache data
                        // for read request, fetch corresponding data
                        // for write request, dirty bit should also be updated
                        if(read_request)
                        begin
                            if(if_accelerator_read) begin
                                accelerator_read_data <= cacheline;
                                read_data <= 32'b0;
                            end
                            else begin
                                accelerator_read_data <= 'b0;
                                read_data <= cache_data[set_addr][return_way][line_addr];
                            end
                        end

                        else if(write_request)
                        begin
                            dirty[set_addr][return_way] <= 1'b1;    // a cache line is dirty when writing a new data into it
                            if(if_accelerator_write) begin
                                for(i=0; i<LINE_SIZE; i=i+1) begin
                                    cache_data[set_addr][return_way][i] <= accelerator_write_data[(LINE_SIZE-i)*32-1-:32];
                                end
                            end
                            else begin
                                case (write_type)
                                `SW:    cache_data[set_addr][return_way][line_addr] <= write_data;
                                
                                `SB: begin
                                    case(addr[1:0])
                                        2'b00:cache_data[set_addr][return_way][line_addr][7:0] <= write_data[7:0];
                                        2'b01:cache_data[set_addr][return_way][line_addr][15:8] <= write_data[7:0];
                                        2'b10:cache_data[set_addr][return_way][line_addr][23:16] <= write_data[7:0];
                                        2'b11:cache_data[set_addr][return_way][line_addr][31:24] <= write_data[7:0];
                                    endcase
                                end   
                                
                                `SH: begin
                                    case (addr[1])
                                        1'b0: cache_data[set_addr][return_way][line_addr][15:0] <= write_data[15:0];
                                        1'b1: cache_data[set_addr][return_way][line_addr][31:16] <= write_data[15:0];
                                    endcase
                                end   
                                default: cache_data[set_addr][return_way][line_addr] <= 'b0;
                            endcase
                            end
                            
                        end

                        else
                        begin
                            read_data <= 32'h00000000;
                        end

                        //update hit count
                        if(request_finish)begin
                            hit_count <= hit_count + 1'b1;
                        end

                        // update cache age and replace way for LRU
                        `ifdef LRU
                        if(request_finish)begin
                            for(w=0; w<WAY_CNT; w=w+1)begin
                                if(valid[set_addr][w])begin
                                    way_age[set_addr][w] <= way_age[set_addr][w] + 1'b1;
                                    if(w == return_way) way_age[set_addr][return_way] <= 32'b0;
                                end 
                            end
                        end
                        `endif
                        
                    end

                    else
                    begin



                        // if request does not hit, then the request cannot be finished
                        request_finish <= 1'b0;
                        // if current request does not hit, change cache state
                        if(read_request | write_request)begin
                            
                            // when miss, miss + 1
                            miss <= miss + 32'b1;

                            // when the line to be replaced is dirty, the state needs to be changed to REPLACE_OUT
                            if(valid[set_addr][replace_way[set_addr]] & dirty[set_addr][replace_way[set_addr]])begin
                                cache_state <= REPLACE_OUT;
                            end
                            else cache_state <= REPLACE_IN;
                        end
                        
                    end
                end 
                
                REPLACE_OUT:
                begin
                    request_finish <= 1'b0;
                    // switch to REPLACE_IN when memory write finishes
                    
                    if(mem_request_finish) begin
                         cache_state <= REPLACE_IN;
                         dirty[set_addr][replace_way[set_addr]] <= 1'b0;
                    end
                end 

                REPLACE_IN:
                begin
                    // When memory read finishes, fill in corresponding cache line,
                    // set the cache line's state, then swtich to READY
                    // From the next cycle, the request is hit.
                    request_finish <= 1'b0;
                    // replace the whole cache line using the address, and update the address at the same time
                    
                    
                    
                    if(mem_request_finish)begin
                        replace_way[set_addr] <= (replace_way[set_addr] + 1'b1) % WAY_CNT;
                        valid[set_addr][replace_way[set_addr]] <= 1'b1;
                        cache_state <= READY;
                    end
                end
            endcase
        end
    end



    // for your ease of debug
    integer out_file;
`ifdef LRU
    initial 
    begin
        if(`TEST_TYPE==0)
        begin
            out_file = $fopen("cache0.txt", "w");
        end
        else if(`TEST_TYPE==1)
        begin
            out_file = $fopen("cache1.txt", "w");
        end
        else if(`TEST_TYPE==2)
        begin
            out_file = $fopen("cache2.txt", "w");
        end
        else if(`TEST_TYPE==3)
        begin
            out_file = $fopen("cache3.txt", "w");
        end
        else
        begin
            out_file = $fopen("cache_else0.txt", "w");
        end
    end
`else
    initial 
    begin
        if(`TEST_TYPE==0)
        begin
            out_file = $fopen("cache4.txt", "w");
        end
        else if(`TEST_TYPE==1)
        begin
            out_file = $fopen("cache5.txt", "w");
        end
        else if(`TEST_TYPE==2)
        begin
            out_file = $fopen("cache6.txt", "w");
        end
        else if(`TEST_TYPE==3)
        begin
            out_file = $fopen("cache7.txt", "w");
        end
        else
        begin
            out_file = $fopen("cache_else1.txt", "w");
        end
    end
`endif

    integer set_index, way_index, line_index;
    always @(posedge clk) 
    begin
        if(debug)
        begin
            for(set_index=0; set_index<SET_SIZE; set_index=set_index+1)
            begin
                for(way_index=0; way_index<WAY_CNT; way_index=way_index+1)
                begin
                    $fwrite(out_file, "%d %d %8h ", valid[set_index][way_index], dirty[set_index][way_index], tag[set_index][way_index]);
`ifdef LRU
                    $fwrite(out_file, "%8h ", way_age[set_index][way_index]);
`endif 
                    for(line_index=0; line_index<LINE_SIZE; line_index=line_index+1)
                    begin
                        $fwrite(out_file, "%8h ", cache_data[set_index][way_index][line_index]);
                    end
                    $fwrite(out_file, "\n");
                end
                $fwrite(out_file, "\n");
            end
        end    
    end

endmodule