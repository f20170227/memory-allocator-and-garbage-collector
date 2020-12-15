# memory-allocator-and-garbage-collector

The file golang.sv contains the parameterized code for memory allocation of various data structures and garbage colection of heap data structure and implementation of these memory allocator and 
garbage collector on physical arrays. Three data structures are taken into consideration : Stack, heap and queue. 

Stack : Stack has been divided into two stacks. We call them stack1 and stack2. Stack1 for static memory allocation e.g. allocation of integer (int x) and stack2 is for dynamic 
memory allocation which will be used when data storage is done in heap. The address of the heap element will be stored in stack2. In stgack1, the data stored in stack1 will be in
LIFO fashion and there is a stack pointer for tracking the data. Stack1 also has the option for push and pop the data and retrieving the data from any given value of stack pointer. One block 
of stack1 is of 8 bits so the data can be stored bytewise in stack1. For stack2, the data will be stored when data is stored in the heap. The address of the particular block of heap
where the data is stored is taken and the address is stored in stack2. The allocation is not LIFO. This is done so that during garbage collection of heap, we can know the address
of heap which is to be removed.

Heap : Heap will be used for dynamic memory allocation. One element of heap is of 24 bits. First byte from LSB is the heap header which will store the necessary information of heap element
and the other two bytes are for storing data in heap. Bit 0 is to tell if the heap block is free or not, 0 for free, 1 for not free, bit 1 tells if the heap block is head or not.
The heap block is composed of either 1,2,3 or 4 elements. This is done to club elements in heap to make a block and is done to store large values in heap. For eg. if one heap block is of 4 elements, the it can have 8 bytes of data stored
in them. This type of data storage also helps for one heap to point to another heap. As the maximum number of elements a heap can have is 4, one heap block can point to a maximum of 
4 heap blocks. This will create a sort of tree structure. The depth of this tree can be at maximum 10. For example, if we want to store the hexadecimal number 2A3F 4444 5F23 in a 
heap then we need 3 heap elements and we need to club these 3 heap elements to form a heap block. The first heap element will have the value 2A3F and as it is the first heap
element, the value of its head field (bit number 1) will be 1 signifying that it is the starting of the heap block, the second heap element will store the value 4444 in its data field and the value of its head field will be 0, the 
third heap element will store the value 5F23 in its data field and the value of its head field will also be 0 signifying that its not the starting of the heap block. Bit number 2-4
is used to tell how many elements are there in its corresponding heap block. If the heap block only has one element, the value will be 001, 010 for two elements, 011 for three elements,
100 for four elements. Bit number 5-6 is used to tell what is the colour of the heap element. 00 means its of white colour, 01 means it is of grey colour, 11 means it is of 
black colour. The colour coding will be used later on in golang's garbage collection. Bit number 7 is used to tell if the heap element is referring to some other heap element or not.
If the value is 1, then its referring to some other heap element and the address of the heap element which it is corresponding to will be stored in the data field of that heap element.
We know that heap will form a tree like data structure, the address of the topmost node of that tree will be stored in stack2. The heap values are store in address ordered best fit allocation and in bitmap allocation scheme as mentioned in the code of bestfit_golang.sv and bitmap_golang.sv respectively.
scheme.

Queue : Queue is the simplest of all the corresponding three data structure, and the data storage is in FIFO fashion. It has two pointers, head and tail. As the data is stored in the
queue, the tail pointer is incremented by 1 and if we want to remove any data from queue, the data corresponding to the front pointer is removed and then its incremented by 1.

So we can remove data from heap and queue as in when required but for data removal in stack, we use a method called garbage collection. In the process of data allocation in heap,
there is a counter called heap_counter. Whenever any data is stored in any heap element, the counter gets incremented by 1 and when the value of the counter reaches 70% of the 
maximum allowed value in heap, a signal called gc (garbage collection) is triggered garbage collection of heap data can take place.

How is garbage collection done?

In the file golang.sv, the golang's tricolor garbage collection method is used. This method of garbage collection is concurrent and the allocator can work at the same time as the 
garbage collector. When the gc signal is triggered, the module of the golang's garbage collector is invoked. Initially, all the objects when allocated are white. First of all, 
stack2 is scanned and then all the heap elements corresponding to the addresses mentioned in stack2 are colored grey. Now, the heap is scanned for the elements which are colored
grey and it colors them black, if the heap element points to any other element, then that element is colored grey. So now, this cycle repeats again and again till the heap is 
completed. Now finally, the heap is scanned once more and all the objects which are still white in color are garbage and are freed from the heap and all the black and grey colored 
objects are retained and they are once again colored white for the next garbage collection cycle. If any object is allocated when the garbage collection is going on, then the 
object is colored grey and it will be checked in the next cycle of garbage collection.

Storing of data structures into physical arrays : 

The data stored in the memory allocation will be stored in physical arrays. Three types of physical arrays are being considered. 824 arrays are of type 1 in which allocation can 
be done of all the three data structures, heap, stack and queue. 100 arrays are of type 2 in which allocation of only stack can be done. 100 arrays are of type 3 in which 
allocation of only queue can be done. The 824 arrays of type 1 are of 512 * 512 bits. There are 512 rows each containing 512 bits. Row number 0 to 122 in each of type1 arrays will be considered for 
storing stack1 data structure. Row number 123 - 245 in each of type1 arrays will be considered for storing queue data structure. Row number 246 - 417 in each of type1 arrays will be considered for storing queue data structure.
Row number 418-511 in each of type1 arrays will be used for storing values in stack2. Row number 512 in each of type1 arrays will be used for other global and local registers which are used. 
The 100 arrays in type 2 are of 256 rows each containing 256 bits. Each of these rows are used in stack1 allocation. The 100 arrays in type 3 are of 256 rows each containing 256 bits. Each of these rows are used in queue allocation.
For stack1, the allocation starts from row 0 of type1 array 0. If the row 0 is completely filled, then allocation is done from row 0 of array 1, and so on till row 0 of type1 array 823. 
If all the row 0  of the 824 arrays are filled, then the allocation will be done from row 1 of type1 array 0. Then it goes to row 1 of array 1 and so on till all the rows of all the 
arrays corresponding to stack1 of all the arrays are filled. Then the data is allocated from row 0 of type2 array 0 and then it goes to row 0 of type2 array 1 and it allocates
in the same manner it allocated stack values in the type1 arrays. Queue is allocated in the exact same way as stack is allocated, the only difference being that the first allocation
will be done on row 123 of type1 array 0 and the last allocation on type1 array will be done on array number 245. Then allocation will be done on type3 row 0 of array 0 and it will
go on till row 0 of type3 array99 and then it will move on to row 1 of type3 array 0 and so on. The allocation of heap is done only on the 824 type1 arrays. First fit allocation
scheme is used to determine allocation on  heap. The allocation will start from row0 of array0 and it will determine when it will get the first free block of the required size. 
If it does not get any free heap block, then it will move on to row 0 of array 1 and so on. Once it gets a free block, the value will be stored in the corresponding physical array
and if the heap is the topmost node of a tree, then the address of the heap block will be stored in the rows corresponding to stack2 of the SAME ARRAY. The heap_counter is a 32 bit 
counter which is stored in the row number 512 of each arrays and it will count how many heap objects are allocated in that array and during garbage collection, the garbage 
objects will be processed in each array parallely during garbage collection, it will happen in all 824 arrays parallely. 

