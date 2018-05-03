//Assignment 3
//Anas Saqib - 103825807
//March 10, 2017

module Assign3_mips(
	CLK
);
	input CLK;


	//PC
	reg [31:0] PC;

	//Rom
	reg [31:0] rom[31:0];  //structure

	reg [4:0] readAddress;  //input

	reg [31:0] instruction;  //output 
	 
	 
	//Control
	reg [5:0] controlInput;  //input 

	reg regDst;   //Control Outputs 
	reg jump;
	reg branch;
	reg memRead;
	reg memToReg;
	reg [1:0] aluOp;
	reg memWrite;
	reg aluSrc;
	reg regWrite;


	//Registers
	reg [31:0] registers [31:0];   //Register Inputs 
	reg [4:0] readRegister1;
	reg [4:0] readRegister2;
	reg [4:0] writeRegister;
	reg [31:0] writeData;

	reg [31:0] readData1;    //Registers Outputs 
	reg [31:0] readData2;

	//ALU
	reg [3:0] aluControl;  
	reg [31:0] aluIn1;   //ALU Inputs 
	reg [31:0] aluIn2;

	reg [31:0] aluResult;   //Output 
	reg aluZero;  //zero flag 

	//Ram
	reg [31:0] ram[31:0];  //structure 
	
	reg [31:0] addressRam;  //Inputs 
	reg [31:0] writeDataRam;

	reg [31:0] readData;  //Output 

	//Adder Results used to handle branching 
	reg [31:0] addResult;

	//Controls Signals from Instruction
	reg [5:0] opcode;
	reg [4:0] rs;
	reg [4:0] rt;
	reg [4:0] rd;
	reg [4:0] shamt;
	reg [5:0] funct;
	reg [15:0] address;

	reg [31:0] immSignEx;  //Instruction[15:0] sign-extended 
	
	reg [31:0] jumpAddress;  //used to handle jumps 
	
	reg [31:0] incPC;   //for handling the incrementation of PC
	
	reg syscall;  //for termination of program
	
	integer i; //For initialising RAM and Registers
	initial
	begin
		//Inititialise RAM and Registers to 0
		for (i=0;i<32;i=i+1) begin
			ram[i] = 32'b0;
			registers[i] = 32'b0;
		end
		//Input ROM 
		rom[0]<=32'b00100100000010000000000000000000;
		rom[1]<=32'b00100100000010010000000000000001;
		rom[2]<=32'b00100100000010100000000000000000;
		rom[3]<=32'b00100100000010110000000000000100;
		rom[4]<=32'b00100100000011000010000000000000;
		rom[5]<=32'b10101101100010100000000000000000;
		rom[6]<=32'b00000001010010010101000000100001;
		rom[7]<=32'b00100101100011000000000000000100;
		rom[8]<=32'b00101101010000010000000000010000;
		rom[9]<=32'b00010100001000001111111111111011;
		rom[10]<=32'b00100101100011000000000000001000;
		rom[11]<=32'b00000001010010010101000000100011;
		rom[12]<=32'b10101101100010101111111111111000;
		rom[13]<=32'b00000001100010110110000000100001;
		rom[14]<=32'b00010001010000000000000000000001;
		rom[15]<=32'b00001000000000000000000000001011;
		rom[16]<=32'b00100100000011000001111111111000;
		rom[17]<=32'b00100100000010110000000000100000;
		rom[18]<=32'b10001101100011010000000000001000;
		rom[19]<=32'b00100101101011011000000000000000;
		rom[20]<=32'b10101101100011010000000000001000;
		rom[21]<=32'b00000001010010010101000000100001;
		rom[22]<=32'b00100101100011000000000000000100;
		rom[23]<=32'b00000001010010110000100000101011;
		rom[24]<=32'b00010100001000001111111111111001;
		rom[25]<=32'b00100100010000100000000000001010;
		rom[26]<=32'b00000000000000000000000000001100;
		
		PC = 32'b0;  //initial PC
		syscall = 1'b0;  //allows program to start
	end 	
	
	always @ (posedge CLK) begin
		readAddress = PC[6:2];  //address from which intruction is taken from rom
		instruction = rom[readAddress];
		opcode = instruction[31:26];
		rs = instruction[25:21];
		rt = instruction[20:16];
		rd = instruction[15:11];
		shamt = instruction[10:6];
		funct = instruction[5:0];
		address = instruction[15:0];
			
		if (opcode==6'b000000 && funct==6'b001100)  //for program termination 
			syscall = 1'b1;
		
		if (syscall==0) begin  
			controlInput = opcode;
			//Control 
			case (controlInput) 		
				6'b000000: begin  //R Type - addu, sltu, subu 
					regDst = 1;
					jump = 0;
					branch = 0;
					memRead = 0;
					memToReg = 0;
					aluOp = 2'b10;
					memWrite = 0;
					aluSrc = 0;
					regWrite = 1;	
				end
				
				6'b100011: begin  //lw
					regDst = 0;
					jump = 0;
					branch = 0;
					memRead = 1;
					memToReg = 1;
					aluOp = 2'b00;
					memWrite = 0;
					aluSrc = 1;
					regWrite = 1;
				end
				
				6'b101011: begin  //sw
					regDst = 0;
					jump = 0;
					branch = 0;
					memRead = 0;
					memToReg = 0;
					aluOp = 2'b00;
					memWrite = 1;
					aluSrc = 1;
					regWrite = 0;
				end
				
				6'b000100: begin  //beq
					regDst = 0;
					jump = 0;
					branch = 1;
					memRead = 0;
					memToReg = 0;
					aluOp = 2'b01;
					memWrite = 0;
					aluSrc = 0;
					regWrite = 0;
				end
				
				6'b001001: begin  //addiu
					regDst = 0;
					jump = 0;
					branch = 0;
					memRead = 0;
					memToReg = 0;
					aluOp = 2'b00;
					memWrite = 0;
					aluSrc = 1;
					regWrite = 1;
				end
				
				6'b000101: begin  //bne
					regDst = 0;
					jump = 0;
					branch = 1;
					memRead = 0;
					memToReg = 0;
					aluOp = 2'b01;
					memWrite = 0;
					aluSrc = 0;
					regWrite = 0;
				end
				
				6'b000010: begin  //j
					regDst = 1;
					jump = 1;
					branch = 0;
					memRead = 0;
					memToReg = 0;
					aluOp = 2'b00;
					memWrite = 0;
					aluSrc = 0;
					regWrite = 0;
				end
				
				6'b001011: begin  //sltiu
					regDst = 0;
					jump = 0;
					branch = 0;
					memRead = 0;
					memToReg = 0;
					aluOp = 2'b11;
					memWrite = 0;
					aluSrc = 1;
					regWrite = 1;
				end
			endcase
			
			//Read Registers 
			readRegister1 = rs;
			readRegister2 = rt;
			readData1 = registers[readRegister1];
			readData2 = registers[readRegister2];
			
			//Set WriteRegister
			if (regDst==0)
				writeRegister = rt;
			else
				writeRegister = rd;
			
			//Sign-extend
			immSignEx [15:0] = instruction[15:0];
			immSignEx [31:16] = {16{instruction[15]}};
			
			//ALU Control
			case (aluOp)
				2'b00: begin  //addiu, lw, sw 
					aluControl = 4'b0000;
				end
				2'b01: begin  //beq, bne
					aluControl = 4'b0001;		
				end
				2'b10: begin  //R Type 
					if (funct==6'b100001)  //addu
						aluControl = 4'b0000;
					else if (funct==6'b101011)  //sltu
						aluControl = 4'b0010;
					else if (funct==6'b100011)  //subu
						aluControl = 4'b0001;
				end
				2'b11: begin  //sltiu
					aluControl = 4'b0010;		
				end
			endcase
		
			//ALU inputs
			aluIn1 = readData1;
			if (aluSrc==0)
				aluIn2 = readData2;
			else
				aluIn2 = immSignEx;
				
			//ALU Result 
			case (aluControl)	
				4'b0000: begin
					aluResult = aluIn1 + aluIn2;
				end			
				4'b0001: begin
					aluResult = aluIn1 - aluIn2;
				end
				4'b0010: begin
					if (aluIn1<aluIn2)
						aluResult = 32'h00000001;
					else
						aluResult = 32'b0;
				end
			endcase
			
			//Zero Flag
			if (aluResult==32'b0)
				aluZero = 1'b1;
			else
				aluZero = 1'b0;

			//RAM
			addressRam = aluResult;	
			writeDataRam = readData2;

			if (memRead==1)  //Reading
				readData = ram[addressRam[6:2]];
			
			if (memWrite==1)  //Writing
				ram[addressRam[6:2]] = writeDataRam;

			//Registers Write
			if (memToReg==0)
				writeData = aluResult;
			else
				writeData = readData;
			if (regWrite==1)
				registers[writeRegister] = writeData;

			//Increment PC	
			incPC = PC+32'h00000004;  
			jumpAddress = {incPC[31:28],instruction[25:0],2'b00};
			addResult = incPC + {immSignEx[29:0],2'b00};
			
			//Set next PC as currentPC+4 by default, then check if needs to be changed
			PC = incPC;
			if (branch==1) begin //handle branching  	
				if (aluZero==1 && opcode==6'b000100) begin   //beq 
					PC = addResult;
				end 
				else if (aluZero==0 && opcode==6'b000101) begin //bne
					PC = addResult;
				end 
			end 
			else if (jump==1)
				PC = jumpAddress;
			
		end 
	end 


endmodule
	
	
	
	
