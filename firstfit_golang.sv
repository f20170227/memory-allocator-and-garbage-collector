// Code with errors removed. The allocator used for heap is first fit and garbage collector is golang's gc

parameter array1_row = 512;
parameter array1_clm = 512;
parameter array2_stack_row = 256;
parameter array2_stack_clm = 256;
parameter array2_queue_row = 256;
parameter array2_queue_clm = 256;
parameter arr1_arrays = 824;
parameter arr2_arrays_stack = 100;
parameter arr2_arrays_queue = 100;
parameter arr1_stack_start = 0;
parameter arr1_stack_end = 122;
parameter arr1_queue_start = 123;
parameter arr1_queue_end = 245;
parameter arr1_heap_start = 246;
parameter arr1_heap_end = 417;
parameter arr1_stack1_start = 418;
parameter arr1_stack1_end = 511;
parameter stack_width = 8;
parameter queue_width = 8;
parameter heap_width = 24; // 16 bits for data, 8 bits for header byte
parameter stack2_width = 13;
parameter depth_of_graph = 10;
parameter arr1_stack_clm_start = 0;

static integer arr1_stack_clm_end = (array1_clm / stack_width) - 1;  // 63
static integer arr1_queue_clm_start = 0;
static integer arr1_queue_clm_end = (array1_clm / queue_width) - 1;  //63
static integer arr1_heap_clm_start = 0;
static integer arr1_heap_clm_end = (array1_clm / heap_width) - 1; //20
static integer arr1_stack1_clm_start = 0;
static integer arr1_stack1_clm_end = (array1_clm / stack2_width) - 1; //38
static integer gc_trigger = (arr1_heap_end - arr1_heap_start + 1) * (array1_row/heap_width) * arr1_arrays * 0.7 ;
static integer stack2_clm = (array2_stack_clm / stack_width); //32
static integer queue2_clm = (array2_queue_clm / queue_width); //32
static integer arr2_stack_clm_end = (array2_stack_clm / stack_width) - 1; //31
static integer arr2_stack_row_end = array2_stack_row - 1; //255
static integer stack_arr1_limit = (arr1_stack1_end - arr1_stack1_start + 1) * (arr1_stack_clm_end + 1) * arr1_arrays; 
static integer stack_arr2_limit = arr2_arrays_stack * array2_stack_row * stack2_clm;
static integer stack_diff = stack_arr1_limit - stack_arr2_limit;
static integer queue_arr1_limit = (arr1_queue_end - arr1_queue_start + 1) * (arr1_queue_clm_end + 1) * arr1_arrays;
static integer queue_arr2_limit = arr2_arrays_queue * array2_queue_row * queue2_clm;
static integer queue_diff = queue_arr1_limit - queue_arr2_limit;


logic memory_physical_arr1 [arr1_arrays][array1_row][array1_clm]; //physical array1
logic memory_physical_arr2_stack [arr2_arrays_stack][array2_stack_row][array2_stack_clm]; // physical array configurable for stack
logic memory_physical_arr2_queue [arr2_arrays_queue][array2_queue_row][array2_queue_clm]; //physical array configurable for queue

// pointers for data structures
static integer stack_ptr_1 = stack_arr1_limit + stack_arr2_limit;
static integer q_ptr_front = 0;         
static integer q_ptr_rear = 0;			
static integer physical_config_q_clm_front = 0;
static integer physical_config_q_row_front = 0;
static integer physical_config_q_arr_front = 0;
static integer q_arr_front;
static integer q_clm_front;
static integer q_row_front;

//logic [23:0]heap_val[824][172][21];/// 16 bits for data(24-8), 1 bit for determining if its poiniting somewhere or not(7), 2 bits for colour(5-6), 3 bits for determining how many blocks are there(2-4), 1 bit for determinig if it is head or not(1)
//1 bit for determining is free or not 0 (0)


reg [31:0] cnt = 0;               // to determine when gc will be triggered
static integer icount=0;
static integer icnt = 0;
reg [31:0] tempcnt=0;
reg [31:0]countarr;
reg [31:0]countarr1;
integer q1 = 0;
integer q = 0;
static integer stack_row = 0;           
static integer stack_clm = 0;        
static integer stack_arr = 0;		 
static integer stack_config = 0;     

static integer q_row = arr1_queue_start;			 
static integer q_clm = 0;			 
static integer q_arr = 0;			 
static integer q_config = 0;		 


static integer heap_row;		 
static integer heap_clm = 0;		 
static integer heap_arr = 0;		 


static integer stack2_arr;				 
static integer stack2_row_ptr = arr1_stack1_start;		 
static integer stack2_clm_ptr = 0;		 
 
static integer physical_config_row = 0;         
static integer physical_config_arr = 0;			
static integer physical_config_clm = 0;			



static integer physical_config_q_row = 0;		
static integer physical_config_q_arr = 0;		
static integer physical_config_q_clm = 0;		


integer i;                                         
integer j;											
integer div;										
integer p;											
integer column_alloc;								
integer alloc_success;								
reg temp;										 
reg temp1;									 
reg temp2;									 
reg temp3; // temporary registers				 
reg [12:0]temp_dynamic_num = 0;							 	
reg gc;
 // temporary registers and integers for gc

integer arr_funct;     
integer j1;		 
integer k;		 
integer m;		 
integer n;		 
integer cnt_c;	 
integer x;		 
integer l;		 
integer y;		 
integer a;		 
integer b;		
integer c;		
reg [23:0]tempx;   
reg [12:0]final_temp;
reg [23:0]treg;		
reg [23:0]temp_c;		
reg [23:0]num1;				
reg [23:0]temp_reg;			
reg [23:0]temp_reg_1;		
reg [2:0]sizex;				
reg [2:0]sizey;				
reg [7:0]tempx_1;			
reg [7:0]tempx_2;    		
reg [4:0]t1;				
reg [7:0]t2;      			  
reg [12:0]temp13;

static integer space;
static integer space1;
static integer space2;
static integer space3;
static integer space_gc;
static integer space_gc1;

static integer zen;
static integer zen_temp;
static integer zen_physical;

// The stack has been seperated into two parts. One part is dedicated to dynamic memory allocation and other is dedicated 
// to non-dynamic memory allocation
 
module count_obj ();
always@(*)
begin
for (icount=0;icount<arr1_arrays;icount++)
begin
for (icnt=0;icnt<32;icnt++)
begin
tempcnt[icnt] = memory_physical_arr1[arr1_arrays][511][icnt];
end
cnt = cnt + tempcnt;
end
end
endmodule


// to determine physical address from a given logical address 
module logical_to_physical_address( input logic [31:0]stack_logic_ptr, output logic arr_type, output logic [31:0]physical_row, 
output logic [31:0]physical_clm, output logic [31:0]physical_arr, output logic [7:0]value);
always@(*)
begin

if (stack_logic_ptr > stack_arr2_limit)
begin
arr_type = 0; // means that its a general array and not an array exclusively for stack
zen_physical = stack_logic_ptr - stack_arr2_limit;
zen = (arr1_stack_end - arr1_stack_start + 1) * (arr1_stack_clm_end + 1);
physical_arr =  (zen_physical) / zen;
zen_temp = (zen_physical) - (physical_arr * zen);
physical_row = zen_temp / (arr1_stack_clm_end + 1);
zen_temp = physical_row * (arr1_stack_clm_end + 1);
physical_clm = (zen_physical) - zen_temp;
zen_temp = physical_clm * stack_width;
for (i=0;i<stack_width;i++)
begin
value[i] = memory_physical_arr1[physical_arr][physical_row][zen_temp + i];
end
end

else
begin
arr_type = 1; //means that it is in array exclusively allocated for stack 
zen = (arr2_stack_clm_end + 1)* (arr2_stack_row_end + 1);
physical_arr = stack_logic_ptr / zen;
zen_temp = (stack_logic_ptr) - (physical_arr * zen);
physical_row = zen_temp / (arr2_stack_clm_end + 1);
zen_temp = physical_row * (arr2_stack_clm_end + 1);
physical_clm = (stack_logic_ptr) - zen_temp;
zen_temp = physical_clm * stack_width;
for (i=0;i<stack_width;i++)
begin
value[i] = memory_physical_arr2_stack[physical_arr][physical_row][zen_temp + i];
end
end

end
endmodule


 
 // First fit allocation scheme
module allocation_x(input logic topnode,input logic remove_stack, input logic [32:0]block_len,  input logic dynamic_alloc, 
input logic qu, input logic enqueue,  input logic refer,output logic [24:0]allocated_size, 
output logic [7:0]read_out_stack, output logic [7:0]read_out_q);
 /// block length is the length of your block you need in bits not bytes for dynamic allocation and length in bytes
 // when you need in non-dynamic allocation
 
 // If you need dynamic allocation, dynami_alloc = 1, 0 for non dynamic allocation
 // If your block is referring to some other block, then refer = 1
 
		
always@(*)
begin

if (dynamic_alloc == 1)
begin

allocated_size = block_len/8;
div = block_len%8;
if (div != 0)
begin
allocated_size = allocated_size + 1;     // we find the size to be allocated in adjustment with the fragmentation
end


if (allocated_size == 1)     // we do not need to merge blocks in this case
begin

	for (heap_row=arr1_heap_start;heap_row<=arr1_heap_end;heap_row++)
	begin

		for (heap_arr=heap_arr;heap_arr<arr1_arrays;heap_arr++)
		begin

			for (heap_clm=heap_clm;heap_clm<=arr1_heap_clm_end;heap_clm++)
			begin
				column_alloc = 0;
				alloc_success = 0;
				space = heap_clm * heap_width;
				temp = memory_physical_arr1[heap_arr][heap_row][space + heap_width - 1];
				if (temp == 0)
				begin
					column_alloc = 1;
					alloc_success = 1;
					if (refer==0)
					begin
				 
						space = heap_clm*heap_width;
						for (i=0;i<heap_width;i++)
						begin
						memory_physical_arr1[heap_arr][heap_row][space+i] = 0; 
						end
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 3] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 2] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 1] = 1;
						if (gc==1)
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 6] = 1;  //if its allocated in the middle of gc, colour will be grey 
						for (q=0;q<31;q++)
						begin
						countarr[q] = memory_physical_arr1[heap_arr][511][q];
						end
						countarr = countarr + 1;
						for (q=0;q<31;q++)
						begin
						memory_physical_arr1[heap_arr][511][q] = countarr[q];
						end
						if (topnode == 1)
						begin
						temp_dynamic_num[4:0] = heap_clm;
						temp_dynamic_num[12:5] = heap_row;
						space = stack2_width * stack2_clm_ptr;
						for (i=0;i<stack2_width;i++)
						begin
						memory_physical_arr1[heap_arr][stack2_row_ptr][space + i] = temp_dynamic_num[i];
						end
						stack2_clm_ptr = stack2_clm_ptr + 1;
						if (stack2_clm_ptr > arr1_stack1_clm_end)
						begin
						stack2_row_ptr = stack2_row_ptr + 1;
						stack2_clm_ptr = 0;
						end
						end
						break;
					end
					else
						begin
						space = heap_clm*heap_width;
						for (i=0;i<heap_width;i++)
						begin
						memory_physical_arr1[heap_arr][heap_row][space+i] = 0; 
						end
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 8] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 3] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 2] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 1] = 1;
						if (gc==1)
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 6] = 1;
						for (q=0;q<31;q++)
						begin
						countarr[q] = memory_physical_arr1[heap_arr][511][q];
						end
						countarr = countarr + 1;
						for (q=0;q<31;q++)
						begin
						memory_physical_arr1[heap_arr][511][q] = countarr[q];
						end
						if (topnode==1)
						begin
						temp_dynamic_num[4:0] = heap_clm;
						temp_dynamic_num[12:5] = heap_row;
						space = stack2_width * stack2_clm_ptr;
						for (i=0;i<stack2_width;i++)
						begin
						memory_physical_arr1[heap_arr][stack2_row_ptr][space + i] = temp_dynamic_num[i];
						end
						stack2_clm_ptr = stack2_clm_ptr + 1;
						if (stack2_clm_ptr > arr1_stack1_clm_end)
						begin
						stack2_row_ptr = stack2_row_ptr + 1;
						stack2_clm_ptr = 0;
						end
						end
						break;
					end
				end
			end
			
			if (column_alloc==1)
			begin
				break;
			end
			
			if (column_alloc==0)
			begin
				heap_clm = 0;
			end

			if (alloc_success==0 && heap_arr == (arr1_arrays - 1) && heap_clm == arr1_heap_clm_end)
			begin
			heap_clm = 0;
			heap_arr = 0;
			end
		end	
		
		if (alloc_success==1)
		begin
		break;
		end
		
	end
end




if (allocated_size == 2)     // we do not need to merge blocks in this case
begin

	for (heap_row=arr1_heap_start;heap_row<=arr1_heap_end;heap_row++)
	begin

		for (heap_arr=heap_arr;heap_arr<arr1_arrays;heap_arr++)
		begin

			for (heap_clm=heap_clm;heap_clm<=arr1_heap_clm_end;heap_clm++)
			begin
				column_alloc = 0;
				alloc_success = 0;
				space = heap_clm * heap_width;
				temp = memory_physical_arr1[heap_arr][heap_row][space + heap_width - 1];
				space1 = (heap_clm+1) * heap_width;
				temp1 = memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 1];
				if (temp == 0 && temp1==0)
				begin
					column_alloc = 1;
					alloc_success = 1;
					if (refer==0)
					begin
						space = heap_clm*heap_width;
						space1 = (heap_clm+1)*heap_width;
						for (i=0;i<heap_width;i++)
						begin
						memory_physical_arr1[heap_arr][heap_row][space+i] = 0; 
						memory_physical_arr1[heap_arr][heap_row][space1+i] = 0; 
						end
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 4] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 2] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 1] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 4] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 1] = 1;
						if (gc==1)
						begin
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 6] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 6] = 1;
						end						
						for (q=0;q<31;q++)
						begin
						countarr[q] = memory_physical_arr1[heap_arr][511][q];
						end
						countarr = countarr + 2;
						for (q=0;q<31;q++)
						begin
						memory_physical_arr1[heap_arr][511][q] = countarr[q];
						end
						if (topnode == 1)
						begin
						temp_dynamic_num[4:0] = heap_clm;
						temp_dynamic_num[12:5] = heap_row;
						space = stack2_width * stack2_clm_ptr;
						for (i=0;i<stack2_width;i++)
						begin
						memory_physical_arr1[heap_arr][stack2_row_ptr][space + i] = temp_dynamic_num[i];
						end
						stack2_clm_ptr = stack2_clm_ptr + 1;
						if (stack2_clm_ptr > arr1_stack1_clm_end)
						begin
						stack2_row_ptr = stack2_row_ptr + 1;
						stack2_clm_ptr = 0;
						end
						end
						break;
					end
					else
						begin
						space = heap_clm*heap_width;
						space1 = (heap_clm+1)*heap_width;
						for (i=0;i<heap_width;i++)
						begin
						memory_physical_arr1[heap_arr][heap_row][space+i] = 0; 
						memory_physical_arr1[heap_arr][heap_row][space1+i] = 0; 
						end
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 4] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 2] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 1] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 8] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 4] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 1] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 8] = 1;
						if (gc==1)
						begin
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 6] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 6] = 1;
						end
						for (q=0;q<31;q++)
						begin
						countarr[q] = memory_physical_arr1[heap_arr][511][q];
						end
						countarr = countarr + 2;
						for (q=0;q<31;q++)
						begin
						memory_physical_arr1[heap_arr][511][q] = countarr[q];
						end
						if (topnode==1)
						begin
						temp_dynamic_num[4:0] = heap_clm;
						temp_dynamic_num[12:5] = heap_row;
						space = stack2_width * stack2_clm_ptr;
						for (i=0;i<stack2_width;i++)
						begin
						memory_physical_arr1[heap_arr][stack2_row_ptr][space + i] = temp_dynamic_num[i];
						end
						stack2_clm_ptr = stack2_clm_ptr + 1;
						if (stack2_clm_ptr > arr1_stack1_clm_end)
						begin
						stack2_row_ptr = stack2_row_ptr + 1;
						stack2_clm_ptr = 0;
						end
						end
						break;
					end
				end
			end
			
			if (column_alloc==1)
			begin
				break;
			end
			
			if (column_alloc==0)
			begin
				heap_clm = 0;
			end

			if (alloc_success==0 && heap_arr == (arr1_arrays - 1) && heap_clm == arr1_heap_clm_end)
			begin
			heap_clm = 0;
			heap_arr = 0;
			end
		end	
		
		if (alloc_success==1)
		begin
		break;
		end
		
	end
end


if (allocated_size == 3)     // we do not need to merge blocks in this case
begin

	for (heap_row=arr1_heap_start;heap_row<=arr1_heap_end;heap_row++)
	begin

		for (heap_arr=heap_arr;heap_arr<arr1_arrays;heap_arr++)
		begin

			for (heap_clm=heap_clm;heap_clm<=arr1_heap_clm_end;heap_clm++)
			begin
				column_alloc = 0;
				alloc_success = 0;
				space = heap_clm * heap_width;
				temp = memory_physical_arr1[heap_arr][heap_row][space + heap_width - 1];
				space1 = (heap_clm+1) * heap_width;
				temp1 = memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 1];
				space2 = (heap_clm+2) * heap_width;
				temp2 = memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 1];
				if (temp == 0 && temp1==0 && temp2==0)
				begin
					column_alloc = 1;
					alloc_success = 1;
					if (refer==0)
					begin
						space = heap_clm * heap_width;
						space1 = (heap_clm+1) * heap_width;
						space2 = (heap_clm+2) * heap_width;
						for (i=0;i<heap_width;i++)
						begin
						memory_physical_arr1[heap_arr][heap_row][space+i] = 0; 
						memory_physical_arr1[heap_arr][heap_row][space1+i] = 0;
						memory_physical_arr1[heap_arr][heap_row][space2+i] = 0; 						
						end
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 4] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 3] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 2] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 1] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 4] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 3] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 1] = 1;
						memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 4] = 1;
						memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 3] = 1;
						memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 1] = 1; 
						if (gc==1)
						begin
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 6] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 6] = 1;
						memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 6] = 1;
						end
						for (q=0;q<31;q++)
						begin
						countarr[q] = memory_physical_arr1[heap_arr][511][q];
						end
						countarr = countarr + 3;
						for (q=0;q<31;q++)
						begin
						memory_physical_arr1[heap_arr][511][q] = countarr[q];
						end
						if (topnode==1)
						begin
						temp_dynamic_num[4:0] = heap_clm;
						temp_dynamic_num[12:5] = heap_row;
						space = stack2_width * stack2_clm_ptr;
						for (i=0;i<stack2_width;i++)
						begin
						memory_physical_arr1[heap_arr][stack2_row_ptr][space + i] = temp_dynamic_num[i];
						end
						stack2_clm_ptr = stack2_clm_ptr + 1;
						if (stack2_clm_ptr > arr1_stack1_clm_end)
						begin
						stack2_row_ptr = stack2_row_ptr + 1;
						stack2_clm_ptr = 0;
						end
						end
						break;
					end
					else
						begin
						space = heap_clm * heap_width;
						space1 = (heap_clm+1) * heap_width;
						space2 = (heap_clm+2) * heap_width;
						for (i=0;i<heap_width;i++)
						begin
						memory_physical_arr1[heap_arr][heap_row][space+i] = 0; 
						memory_physical_arr1[heap_arr][heap_row][space1+i] = 0;
						memory_physical_arr1[heap_arr][heap_row][space2+i] = 0; 						
						end
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 4] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 3] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 2] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 1] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 8] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 4] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 3] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 1] = 1;
						memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 8] = 1;
						memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 4] = 1;
						memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 3] = 1;
						memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 1] = 1;
						memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 8] = 1;
						if (gc==1)
						begin
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 6] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 6] = 1;
						memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 6] = 1;
						end
						for (q=0;q<31;q++)
						begin
						countarr[q] = memory_physical_arr1[heap_arr][511][q];
						end
						countarr = countarr + 3;
						for (q=0;q<31;q++)
						begin
						memory_physical_arr1[heap_arr][511][q] = countarr[q];
						end
						if (topnode==1)
						begin
						temp_dynamic_num[4:0] = heap_clm;
						temp_dynamic_num[12:5] = heap_row;
						space = stack2_width * stack2_clm_ptr;
						for (i=0;i<stack2_width;i++)
						begin
						memory_physical_arr1[heap_arr][stack2_row_ptr][space + i] = temp_dynamic_num[i];
						end
						stack2_clm_ptr = stack2_clm_ptr + 1;
						if (stack2_clm_ptr > arr1_stack1_clm_end)
						begin
						stack2_row_ptr = stack2_row_ptr + 1;
						stack2_clm_ptr = 0;
						end
						end
						break;
					end
				end
			end
			
			if (column_alloc==1)
			begin
				break;
			end
			
			if (column_alloc==0)
			begin
				heap_clm = 0;
			end

			if (alloc_success==0 && heap_arr == (arr1_arrays - 1) && heap_clm == arr1_heap_clm_end)
			begin
			heap_clm = 0;
			heap_arr = 0;
			end
		end	
		
		if (alloc_success==1)
		begin
		break;
		end
		
	end
end


if (allocated_size == 4)     // we do not need to merge blocks in this case
begin

	for (heap_row=arr1_heap_start;heap_row<=arr1_heap_end;heap_row++)
	begin

		for (heap_arr=heap_arr;heap_arr<arr1_arrays;heap_arr++)
		begin

			for (heap_clm=heap_clm;heap_clm<=arr1_heap_clm_end;heap_clm++)
			begin
				column_alloc = 0;
				alloc_success = 0;
				space = heap_clm * heap_width;
				temp = memory_physical_arr1[heap_arr][heap_row][space + heap_width - 1];
				space1 = (heap_clm+1) * heap_width;
				temp1 = memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 1];
				space2 = (heap_clm+2) * heap_width;
				temp2 = memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 1];
				space3 = (heap_clm+3) * heap_width;
				temp3 = memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 1];

				if (temp == 0 && temp1==0 && temp2 == 0 && temp3==0)
				begin
					column_alloc = 1;
					alloc_success = 1;
					if (refer==0)
					begin
						
						space = heap_clm * heap_width;
						space1 = (heap_clm+1) * heap_width;
						space2 = (heap_clm+2) * heap_width;
						space3 = (heap_clm+3) * heap_width;
						for (i=0;i<heap_width;i++)
						begin
						memory_physical_arr1[heap_arr][heap_row][space+i] = 0; 
						memory_physical_arr1[heap_arr][heap_row][space1+i] = 0;
						memory_physical_arr1[heap_arr][heap_row][space2+i] = 0;
						memory_physical_arr1[heap_arr][heap_row][space3+i] = 0; 						
						end
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 5] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 2] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 1] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 5] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 1] = 1;
						memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 5] = 1;
						memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 1] = 1; 
						memory_physical_arr1[heap_arr][heap_row][space3 + heap_width - 5] = 1;
						memory_physical_arr1[heap_arr][heap_row][space3 + heap_width - 1] = 1; 
						if (gc==1)
						begin
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 6] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 6] = 1;
						memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 6] = 1;
						memory_physical_arr1[heap_arr][heap_row][space3 + heap_width - 6] = 1;
						end
						for (q=0;q<31;q++)
						begin
						countarr[q] = memory_physical_arr1[heap_arr][511][q];
						end
						countarr = countarr + 4;
						for (q=0;q<31;q++)
						begin
						memory_physical_arr1[heap_arr][511][q] = countarr[q];
						end
						if (topnode==1)
						begin
						temp_dynamic_num[4:0] = heap_clm;
						temp_dynamic_num[12:5] = heap_row;
						space = stack2_width * stack2_clm_ptr;
						for (i=0;i<stack2_width;i++)
						begin
						memory_physical_arr1[heap_arr][stack2_row_ptr][space + i] = temp_dynamic_num[i];
						end
						stack2_clm_ptr = stack2_clm_ptr + 1;
						if (stack2_clm_ptr > arr1_stack1_clm_end)
						begin
						stack2_row_ptr = stack2_row_ptr + 1;
						stack2_clm_ptr = 0;
						end
						end
						break;
					end
					else
						begin
						space = heap_clm * heap_width;
						space1 = (heap_clm+1) * heap_width;
						space2 = (heap_clm+2) * heap_width;
						space3 = (heap_clm+3) * heap_width;
						for (i=0;i<heap_width;i++)
						begin
						memory_physical_arr1[heap_arr][heap_row][space+i] = 0; 
						memory_physical_arr1[heap_arr][heap_row][space1+i] = 0;
						memory_physical_arr1[heap_arr][heap_row][space2+i] = 0;
						memory_physical_arr1[heap_arr][heap_row][space3+i] = 0; 						
						end
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 5] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 2] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 1] = 1;
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 8] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 5] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 1] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 8] = 1;
						memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 5] = 1;
						memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 1] = 1; 
						memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 8] = 1;
						memory_physical_arr1[heap_arr][heap_row][space3 + heap_width - 5] = 1;
						memory_physical_arr1[heap_arr][heap_row][space3 + heap_width - 1] = 1;
						memory_physical_arr1[heap_arr][heap_row][space3 + heap_width - 8] = 1;
						if (gc==1)
						begin
						memory_physical_arr1[heap_arr][heap_row][space + heap_width - 6] = 1;
						memory_physical_arr1[heap_arr][heap_row][space1 + heap_width - 6] = 1;
						memory_physical_arr1[heap_arr][heap_row][space2 + heap_width - 6] = 1;
						memory_physical_arr1[heap_arr][heap_row][space3 + heap_width - 6] = 1;
						end
						for (q=0;q<31;q++)
						begin
						countarr[q] = memory_physical_arr1[heap_arr][511][q];
						end
						countarr = countarr + 4;
						for (q=0;q<31;q++)
						begin
						memory_physical_arr1[heap_arr][511][q] = countarr[q];
						end
						if (topnode==1)
						begin
						temp_dynamic_num[4:0] = heap_clm;
						temp_dynamic_num[12:5] = heap_row;
						space = stack2_width * stack2_clm_ptr;
						for (i=0;i<stack2_width;i++)
						begin
						memory_physical_arr1[heap_arr][stack2_row_ptr][space + i] = temp_dynamic_num[i];
						end
						stack2_clm_ptr = stack2_clm_ptr + 1;
						if (stack2_clm_ptr > arr1_stack1_clm_end)
						begin
						stack2_row_ptr = stack2_row_ptr + 1;
						stack2_clm_ptr = 0;
						end
						end
						break;
					end
				end
			end
			
			if (column_alloc==1)
			begin
				break;
			end
			
			if (column_alloc==0)
			begin
				heap_clm = 0;
			end

			if (alloc_success==0 && heap_arr == (arr1_arrays - 1) && heap_clm == arr1_heap_clm_end)
			begin
			heap_clm = 0;
			heap_arr = 0;
			end
		end	
		
		if (alloc_success==1)
		begin
		break;
		end
		
	end
end


if (cnt >= gc_trigger )     // The heap is of length 3729424, so if the heap counter is greater than 2694808, gc will be triggered
begin
gc = 1;
end

else
begin
gc = 0;
end

end

if (dynamic_alloc == 0)    // non-dynamic memory allocation
begin
	// block_len tells how many bytes of memory do we need
	// this module allows to either push an element on the stack or pop an element from the stack
	if (qu==0 && remove_stack == 0)
	begin
		for (j=0;j<block_len;j++)
		begin
			stack_ptr_1 = stack_ptr_1 - 1;
			   // assume that the data allocated is 0.
			
			
			// to allocate stack into physical memory arrays
			if (stack_config==0 || stack_ptr_1 > stack_arr2_limit)
			begin
					space = stack_clm * stack_width;
					for (i=0;i<stack_width;i++)
					begin
					memory_physical_arr1[stack_arr][stack_row][space + i] = 0;
					end
					stack_clm = stack_clm + 1;
					if (stack_clm > arr1_stack_clm_end && stack_arr < arr1_arrays)
					begin
						stack_arr = stack_arr + 1;
						stack_clm = 0;
					end
					
					if (stack_arr == arr1_arrays && stack_row < arr1_stack_end && stack_clm == arr1_stack_clm_end)
					begin
						stack_row = stack_row + 1;
						stack_arr = 0;
						stack_clm = 0;
					end
					
					if (stack_arr == arr1_arrays && stack_row == arr1_stack_end && stack_clm == arr1_stack_clm_end)
					begin
						stack_config = 1;
					end
			end
			if (stack_ptr_1 < stack_arr2_limit || stack_config==1)
			begin
				space = physical_config_clm * stack_width;
					for (i=0;i<stack_width;i++)
					begin
					memory_physical_arr2_stack[physical_config_arr][physical_config_row][space + i] = 0;
					end
				physical_config_clm = physical_config_clm + 1;
				if (physical_config_clm > arr2_stack_clm_end)
				begin
				physical_config_clm = 0;
				physical_config_arr = physical_config_arr + 1;
				end
				if (physical_config_arr > arr2_arrays_stack)
				begin
				physical_config_clm = 0;
				physical_config_arr = 0;
				physical_config_row = physical_config_row + 1;
				end
			end
		end
	end
	
	// popping an element fom the stack
	if (remove_stack == 1 && ((stack_ptr_1+1) > stack_arr2_limit))
	begin
	
	if (stack_clm != arr1_stack_clm_start)
	begin
	stack_clm = stack_clm - 1;
	end
	if (stack_clm == arr1_stack_clm_start && stack_arr != 0)
	begin
	stack_clm = arr1_stack1_clm_end;
	stack_arr = stack_arr - 1;
	end
	if (stack_clm == arr1_stack_clm_start && stack_arr == 0)
	begin
	stack_clm = arr1_stack1_clm_end;
	stack_arr = (arr1_arrays - 1);
	stack_clm = stack_clm - 1;
	end
	stack_ptr_1 = stack_ptr_1 + 1;
	space = stack_clm * stack_width;
	for (i=0;i<stack_width;i++)
	begin
	read_out_stack[i] = memory_physical_arr1[stack_arr][stack_row][space + i];
	memory_physical_arr1[stack_arr][stack_row][space + i] = 1'bx;
	end
	end
	
	if (remove_stack == 1 && ((stack_ptr_1+1) < stack_arr2_limit))
	begin
	if (stack_clm != 0)
	begin
	physical_config_clm = physical_config_clm - 1;
	end
	if (physical_config_clm == 0 && physical_config_arr != 0)
	begin
	physical_config_clm = arr2_stack_clm_end;
	physical_config_arr = physical_config_arr - 1;
	end
	if (physical_config_clm == 0 && physical_config_arr == 0)
	begin
	physical_config_clm = arr2_stack_clm_end;
	physical_config_arr = (arr2_arrays_stack - 1);
	physical_config_row = physical_config_row - 1;
	end
	stack_ptr_1 = stack_ptr_1 + 1;
	space = physical_config_clm * stack_width;
	for (i=0;i<stack_width;i++)
	begin
	read_out_stack[i] = memory_physical_arr2_stack[physical_config_arr][physical_config_row][space + i];
	memory_physical_arr2_stack[physical_config_arr][physical_config_row][space + i] = 1'bx;
	end
	end
	
	

	if (qu==1)
	begin

		if (enqueue==1)
		begin

			for (p=0;p<block_len;p++)
			begin
						
			
			if (q_config==0 || q_ptr_rear <= queue_arr1_limit)
			begin
				space = q_clm * queue_width;
					for (i=0;i<queue_width;i++)
					begin
					memory_physical_arr1[q_arr][q_row][space + i] = 0;
					end
				q_ptr_rear = q_ptr_rear + 1;
				q_clm = q_clm + 1;
				
				if (q_clm > arr1_queue_clm_end && q_arr <= arr1_arrays)
				begin
					q_arr = q_arr + 1;
					q_clm = 0;
				end
				
				if (q_arr == arr1_arrays && q_row < arr1_queue_end && q_clm == arr1_queue_clm_end)
				begin
					q_row = q_row + 1;
					q_arr = 0;
					q_clm = 0;
				end
				
				if (q_arr == arr1_arrays && q_row == arr1_queue_end && q_clm == arr1_queue_clm_end)
				begin
					q_config = 1;
				end
			end
			
			
			if (q_config == 1 || q_ptr_rear > queue_arr1_limit)
			begin
			
			space = physical_config_q_clm * queue_width;
					for (i=0;i<stack_width;i++)
					begin
					memory_physical_arr2_queue[physical_config_q_arr][physical_config_q_row][space + i] = 0;
					end
			physical_config_q_clm = physical_config_q_clm + 1;
			if (physical_config_q_clm > (queue2_clm - 1))
			begin
			physical_config_q_clm = 0;
			physical_config_q_arr = physical_config_q_arr + 1;
			end
			if (physical_config_q_arr>(arr2_arrays_queue-1))
			begin
			physical_config_q_clm = 0;
			physical_config_q_arr = 0;
			physical_config_q_row = physical_config_q_row + 1;
			end
			end
			end
			
			
			
		end

		if (enqueue==0)
		begin
			
			if (q_ptr_front <= queue_arr1_limit)
			begin
			space = q_clm_front * queue_width;
			for (i=0;i<queue_width;i++)
			begin
			read_out_q = memory_physical_arr1[q_arr_front][q_row_front][space + i];
			end
			q_ptr_front = q_ptr_front + 1;
			
			q_clm_front = q_clm_front + 1;
				
				if (q_clm_front > arr1_queue_clm_end && q_arr_front <= arr1_arrays)
				begin
					q_arr_front = q_arr_front + 1;
					q_clm_front = 0;
				end
				
				if (q_arr_front == arr1_arrays && q_row_front < arr1_queue_end && q_clm_front == arr1_queue_clm_end)
				begin
					q_row_front = q_row_front + 1;
					q_arr_front = 0;
					q_clm_front = 0;
				end
			end
			
			else
			begin
			
			space = physical_config_q_clm_front * queue_width;
			for (i=0;i<stack_width;i++)
			begin
			read_out_q = memory_physical_arr2_queue[physical_config_q_arr_front][physical_config_q_row_front][space + i];
			end
			q_ptr_front = q_ptr_front + 1;
			
			physical_config_q_clm_front = physical_config_q_clm_front + 1;
			if (physical_config_q_clm_front > (queue2_clm - 1))
			begin
			physical_config_q_clm_front = 0;
			physical_config_q_arr_front = physical_config_q_arr_front + 1;
			end
			if (physical_config_q_arr_front>(arr2_arrays_queue-1))
			begin
			physical_config_q_clm_front = 0;
			physical_config_q_arr_front = 0;
			physical_config_q_row_front = physical_config_q_row_front + 1;
			end
			
			end
			
		end
	end	
	
	
end 
end
endmodule



// golang's tricolour garbage collector
module garbage_collection_g1 (input logic arr_funct);


always@(posedge gc)
begin


// then go to the stack for dynamic allocation and check each stack block one by one and colour the raechable objects grey

	for (j1=arr1_stack1_start;j1<=arr1_stack1_end;j1++)
	begin
		for (k=0;k<=arr1_stack1_clm_end;k++)
		begin

			space_gc = stack2_width * k;
			for (i=0;i<5;i++)
			begin
			t1[i] = memory_physical_arr1[arr_funct][j1][space_gc+stack2_width-1-i];
			end
			for (i=0;i<8;i++)
			begin
			t2[i] = memory_physical_arr1[arr_funct][j1][space_gc+stack2_width-6-i];
			end
			sizey[0] = memory_physical_arr1[arr_funct][t2+arr1_heap_start][t1+heap_width-3];
			sizey[1] = memory_physical_arr1[arr_funct][t2+arr1_heap_start][t1+heap_width-4];
			sizey[2] = memory_physical_arr1[arr_funct][t2+arr1_heap_start][t1+heap_width-5];
			for (n=0;n<sizey;n++)
			begin
			
				memory_physical_arr1[arr_funct][t2][t1 + n + heap_width - 6] = 0;
				memory_physical_arr1[arr_funct][j1][t1 + n + heap_width - 7] = 1;       // 01 is for grey colour
	   
			end
		end
	end



for (l=0;l<depth_of_graph;l++)          // the depth of the heap graph is limited to 10
begin

	cnt_c = 0;
		for (j1=arr1_heap_start;j1<=arr1_heap_end;j1++)
		begin
			for (k=0;k<arr1_heap_clm_end;k++)
			begin

	for (i=0;i<heap_width;i++)
	begin
	tempx[i] = memory_physical_arr1[arr_funct][j1][k+heap_width-1-i];
	end
	sizex = tempx[4:2];               // one object can point to a maximum of 4 objects so the max value of sizex is 4
	if (tempx[5] == 1 && tempx[6]==0)
	begin
	cnt_c = cnt_c + 1;
	if (tempx[7]==1)
	begin
	for (y=0;y<sizex;y++)
	begin
	for (i=0;i<heap_width;i++)
	begin
	num1[i] = memory_physical_arr1[arr_funct][j1][k+y+heap_width-1-i];
	end
	tempx_1 = num1[12:8];
	tempx_2 = num1[20:13];
	for (i=0;i<heap_width;i++)
	begin
	temp_reg[i] = memory_physical_arr1[arr_funct][tempx_2 + arr1_heap_start][tempx_1 + heap_width-1-i];
	end
	temp_reg[6:5] = 2'b01;
	for (i=0;i<heap_width;i++)
	begin
	memory_physical_arr1[arr_funct][tempx_2 + arr1_heap_start][tempx_1 + heap_width-1-i] = temp_reg[i];    // choosing a parent object and colouring their child objects with grey
	end
	end
	end
	for (i=0;i<heap_width;i++)
	begin
	temp_reg_1[i] = memory_physical_arr1[arr_funct][j1][k+heap_width-1-i];
	end
	temp_reg_1[6:5] = 2'b11;
	for (i=0;i<heap_width;i++)
	begin
	memory_physical_arr1[arr_funct][j1][k+heap_width-1-i] = temp_reg_1[i];    // 11 is for black colour
	end
	end
	end
	end
	if (cnt_c == 0)
	begin
	break;
	end
	

end



	for (j1=arr1_heap_start;j1<=arr1_heap_end;j1++)
	begin
		for (k=0;k<heap_width;k++)
		begin                         // garbage collect the objects which are of white colour

			space_gc = k * heap_width;
			for (i=0;i<heap_width;i++)
			begin
			temp_c[i] = memory_physical_arr1[arr_funct][j1][space_gc+heap_width-1-i];
			end
			if (temp_c[6:5] == 2'b00 && temp_c[0]==1)
			begin
				temp_c[0] = 0;
				for (q1=0;q1<31;q1++)
				begin
				countarr1[q1] = memory_physical_arr1[arr_funct][511][q1];
				end
				countarr1 = countarr1 - 1;
				for (q1=0;q1<31;q1++)
				begin
				memory_physical_arr1[arr_funct][511][q1] = countarr1[q1];
				end
				for (i=0;i<heap_width;i++)
				begin
				memory_physical_arr1[arr_funct][j1][space_gc+heap_width-1-i] = temp_c[i];
				end
				final_temp[4:0] = k;
				final_temp[12:5] = j1;
				

				
					for (b=arr1_stack1_start;b<=arr1_stack1_end;b++)
					begin
						for (c=0;c<arr1_stack1_clm_end;c++)
						begin
							space_gc1 = c * stack2_width;
							for (i=0;i<stack2_width;i++)
							begin
							temp13[i] = memory_physical_arr1[arr_funct][b][space_gc1+stack2_width-1-i];
							end
							if (temp13 == final_temp)
							begin
								for (i=0;i<stack2_width;i++)
								begin
								memory_physical_arr1[arr_funct][b][space_gc1+stack2_width-1-i] = 1'bx;
								end
								break;
							end
						end
						break;
					end
					break;
				

			end
			else
			begin
				if (temp_c[6:5] == 2'b11)
				temp_c[6:5] = 2'b00;
				for (i=0;i<heap_width;i++)
				begin
				memory_physical_arr1[arr_funct][j1][space_gc+heap_width-1-i] = temp_c[i];
				end
			end
		end

	end
end


endmodule




module gc_total();
genvar jk;	
generate
for (jk = 0;jk < arr1_arrays; jk++)
begin
garbage_collection_g1 A1 (jk);
end
endgenerate
endmodule
