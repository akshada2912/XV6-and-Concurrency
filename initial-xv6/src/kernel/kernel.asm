
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a3010113          	addi	sp,sp,-1488 # 80008a30 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	89e70713          	addi	a4,a4,-1890 # 800088f0 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	43c78793          	addi	a5,a5,1084 # 800064a0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbbe87>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	e3078793          	addi	a5,a5,-464 # 80000ede <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	830080e7          	jalr	-2000(ra) # 8000295c <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8a650513          	addi	a0,a0,-1882 # 80010a30 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	aaa080e7          	jalr	-1366(ra) # 80000c3c <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	89648493          	addi	s1,s1,-1898 # 80010a30 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	92690913          	addi	s2,s2,-1754 # 80010ac8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	90c080e7          	jalr	-1780(ra) # 80001acc <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	5de080e7          	jalr	1502(ra) # 800027a6 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	31c080e7          	jalr	796(ra) # 800024f2 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	6f4080e7          	jalr	1780(ra) # 80002906 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	80a50513          	addi	a0,a0,-2038 # 80010a30 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	ac2080e7          	jalr	-1342(ra) # 80000cf0 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00010517          	auipc	a0,0x10
    80000240:	7f450513          	addi	a0,a0,2036 # 80010a30 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	aac080e7          	jalr	-1364(ra) # 80000cf0 <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	84f72b23          	sw	a5,-1962(a4) # 80010ac8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	76450513          	addi	a0,a0,1892 # 80010a30 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	968080e7          	jalr	-1688(ra) # 80000c3c <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	6c0080e7          	jalr	1728(ra) # 800029b2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	73650513          	addi	a0,a0,1846 # 80010a30 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9ee080e7          	jalr	-1554(ra) # 80000cf0 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	71270713          	addi	a4,a4,1810 # 80010a30 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	6e878793          	addi	a5,a5,1768 # 80010a30 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7527a783          	lw	a5,1874(a5) # 80010ac8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6a670713          	addi	a4,a4,1702 # 80010a30 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	69648493          	addi	s1,s1,1686 # 80010a30 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	65a70713          	addi	a4,a4,1626 # 80010a30 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	6ef72223          	sw	a5,1764(a4) # 80010ad0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	61e78793          	addi	a5,a5,1566 # 80010a30 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	68c7ab23          	sw	a2,1686(a5) # 80010acc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	68a50513          	addi	a0,a0,1674 # 80010ac8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	110080e7          	jalr	272(ra) # 80002556 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5d050513          	addi	a0,a0,1488 # 80010a30 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	744080e7          	jalr	1860(ra) # 80000bac <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00241797          	auipc	a5,0x241
    8000047c:	36878793          	addi	a5,a5,872 # 802417e0 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5a07a323          	sw	zero,1446(a5) # 80010af0 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	32f72923          	sw	a5,818(a4) # 800088b0 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	536dad83          	lw	s11,1334(s11) # 80010af0 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	4e050513          	addi	a0,a0,1248 # 80010ad8 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	63c080e7          	jalr	1596(ra) # 80000c3c <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	38250513          	addi	a0,a0,898 # 80010ad8 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	592080e7          	jalr	1426(ra) # 80000cf0 <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	36648493          	addi	s1,s1,870 # 80010ad8 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	428080e7          	jalr	1064(ra) # 80000bac <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	32650513          	addi	a0,a0,806 # 80010af8 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	3d2080e7          	jalr	978(ra) # 80000bac <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	3fa080e7          	jalr	1018(ra) # 80000bf0 <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	0b27a783          	lw	a5,178(a5) # 800088b0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	46c080e7          	jalr	1132(ra) # 80000c90 <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0827b783          	ld	a5,130(a5) # 800088b8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	08273703          	ld	a4,130(a4) # 800088c0 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	298a0a13          	addi	s4,s4,664 # 80010af8 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	05048493          	addi	s1,s1,80 # 800088b8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	05098993          	addi	s3,s3,80 # 800088c0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	cc4080e7          	jalr	-828(ra) # 80002556 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	22a50513          	addi	a0,a0,554 # 80010af8 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	366080e7          	jalr	870(ra) # 80000c3c <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	fd27a783          	lw	a5,-46(a5) # 800088b0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	fd873703          	ld	a4,-40(a4) # 800088c0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	fc87b783          	ld	a5,-56(a5) # 800088b8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	1fc98993          	addi	s3,s3,508 # 80010af8 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	fb448493          	addi	s1,s1,-76 # 800088b8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	fb490913          	addi	s2,s2,-76 # 800088c0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	bd6080e7          	jalr	-1066(ra) # 800024f2 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	1c648493          	addi	s1,s1,454 # 80010af8 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	f6e7bd23          	sd	a4,-134(a5) # 800088c0 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	398080e7          	jalr	920(ra) # 80000cf0 <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	13c48493          	addi	s1,s1,316 # 80010af8 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	276080e7          	jalr	630(ra) # 80000c3c <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	318080e7          	jalr	792(ra) # 80000cf0 <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    800009ea:	7179                	addi	sp,sp,-48
    800009ec:	f406                	sd	ra,40(sp)
    800009ee:	f022                	sd	s0,32(sp)
    800009f0:	ec26                	sd	s1,24(sp)
    800009f2:	e84a                	sd	s2,16(sp)
    800009f4:	e44e                	sd	s3,8(sp)
    800009f6:	1800                	addi	s0,sp,48
  struct run *r;
  int temp;

  if (((uint64)pa % 4096) != 0 || (char *)pa < end || (uint64)pa >= (0x80000000L + 128 * 1024 * 1024))
    800009f8:	03451793          	slli	a5,a0,0x34
    800009fc:	e3ad                	bnez	a5,80000a5e <kfree+0x74>
    800009fe:	84aa                	mv	s1,a0
    80000a00:	00242797          	auipc	a5,0x242
    80000a04:	f7878793          	addi	a5,a5,-136 # 80242978 <end>
    80000a08:	04f56b63          	bltu	a0,a5,80000a5e <kfree+0x74>
    80000a0c:	47c5                	li	a5,17
    80000a0e:	07ee                	slli	a5,a5,0x1b
    80000a10:	04f57763          	bgeu	a0,a5,80000a5e <kfree+0x74>
    panic("kfree");

  r = (struct run *)pa;

  acquire(&reference_lock);
    80000a14:	00010917          	auipc	s2,0x10
    80000a18:	11c90913          	addi	s2,s2,284 # 80010b30 <reference_lock>
    80000a1c:	854a                	mv	a0,s2
    80000a1e:	00000097          	auipc	ra,0x0
    80000a22:	21e080e7          	jalr	542(ra) # 80000c3c <acquire>
  reference_count[(uint64)pa/4096] -= 1;
    80000a26:	00c4d793          	srli	a5,s1,0xc
    80000a2a:	00279713          	slli	a4,a5,0x2
    80000a2e:	00010797          	auipc	a5,0x10
    80000a32:	13a78793          	addi	a5,a5,314 # 80010b68 <reference_count>
    80000a36:	97ba                	add	a5,a5,a4
    80000a38:	4398                	lw	a4,0(a5)
    80000a3a:	377d                	addiw	a4,a4,-1
    80000a3c:	0007099b          	sext.w	s3,a4
    80000a40:	c398                	sw	a4,0(a5)
  temp = reference_count[(uint64)pa/4096];
  release(&reference_lock);
    80000a42:	854a                	mv	a0,s2
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	2ac080e7          	jalr	684(ra) # 80000cf0 <release>

  if (temp > 0)
    80000a4c:	03305163          	blez	s3,80000a6e <kfree+0x84>

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}
    80000a50:	70a2                	ld	ra,40(sp)
    80000a52:	7402                	ld	s0,32(sp)
    80000a54:	64e2                	ld	s1,24(sp)
    80000a56:	6942                	ld	s2,16(sp)
    80000a58:	69a2                	ld	s3,8(sp)
    80000a5a:	6145                	addi	sp,sp,48
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>
  memset(pa, 1, PGSIZE);
    80000a6e:	6605                	lui	a2,0x1
    80000a70:	4585                	li	a1,1
    80000a72:	8526                	mv	a0,s1
    80000a74:	00000097          	auipc	ra,0x0
    80000a78:	2c4080e7          	jalr	708(ra) # 80000d38 <memset>
  acquire(&kmem.lock);
    80000a7c:	89ca                	mv	s3,s2
    80000a7e:	00010917          	auipc	s2,0x10
    80000a82:	0ca90913          	addi	s2,s2,202 # 80010b48 <kmem>
    80000a86:	854a                	mv	a0,s2
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	1b4080e7          	jalr	436(ra) # 80000c3c <acquire>
  r->next = kmem.freelist;
    80000a90:	0309b783          	ld	a5,48(s3)
    80000a94:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a96:	0299b823          	sd	s1,48(s3)
  release(&kmem.lock);
    80000a9a:	854a                	mv	a0,s2
    80000a9c:	00000097          	auipc	ra,0x0
    80000aa0:	254080e7          	jalr	596(ra) # 80000cf0 <release>
    80000aa4:	b775                	j	80000a50 <kfree+0x66>

0000000080000aa6 <freerange>:
{
    80000aa6:	7179                	addi	sp,sp,-48
    80000aa8:	f406                	sd	ra,40(sp)
    80000aaa:	f022                	sd	s0,32(sp)
    80000aac:	ec26                	sd	s1,24(sp)
    80000aae:	e84a                	sd	s2,16(sp)
    80000ab0:	e44e                	sd	s3,8(sp)
    80000ab2:	e052                	sd	s4,0(sp)
    80000ab4:	1800                	addi	s0,sp,48
  p = (char *)PGROUNDUP((uint64)pa_start);
    80000ab6:	6785                	lui	a5,0x1
    80000ab8:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000abc:	94aa                	add	s1,s1,a0
    80000abe:	757d                	lui	a0,0xfffff
    80000ac0:	8ce9                	and	s1,s1,a0
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000ac2:	94be                	add	s1,s1,a5
    80000ac4:	0095ee63          	bltu	a1,s1,80000ae0 <freerange+0x3a>
    80000ac8:	892e                	mv	s2,a1
    kfree(p);
    80000aca:	7a7d                	lui	s4,0xfffff
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000acc:	6985                	lui	s3,0x1
    kfree(p);
    80000ace:	01448533          	add	a0,s1,s4
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	f18080e7          	jalr	-232(ra) # 800009ea <kfree>
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000ada:	94ce                	add	s1,s1,s3
    80000adc:	fe9979e3          	bgeu	s2,s1,80000ace <freerange+0x28>
}
    80000ae0:	70a2                	ld	ra,40(sp)
    80000ae2:	7402                	ld	s0,32(sp)
    80000ae4:	64e2                	ld	s1,24(sp)
    80000ae6:	6942                	ld	s2,16(sp)
    80000ae8:	69a2                	ld	s3,8(sp)
    80000aea:	6a02                	ld	s4,0(sp)
    80000aec:	6145                	addi	sp,sp,48
    80000aee:	8082                	ret

0000000080000af0 <kinit>:
{
    80000af0:	1141                	addi	sp,sp,-16
    80000af2:	e406                	sd	ra,8(sp)
    80000af4:	e022                	sd	s0,0(sp)
    80000af6:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000af8:	00007597          	auipc	a1,0x7
    80000afc:	57058593          	addi	a1,a1,1392 # 80008068 <digits+0x28>
    80000b00:	00010517          	auipc	a0,0x10
    80000b04:	04850513          	addi	a0,a0,72 # 80010b48 <kmem>
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0a4080e7          	jalr	164(ra) # 80000bac <initlock>
  freerange(end, (void *)PHYSTOP);
    80000b10:	45c5                	li	a1,17
    80000b12:	05ee                	slli	a1,a1,0x1b
    80000b14:	00242517          	auipc	a0,0x242
    80000b18:	e6450513          	addi	a0,a0,-412 # 80242978 <end>
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	f8a080e7          	jalr	-118(ra) # 80000aa6 <freerange>
}
    80000b24:	60a2                	ld	ra,8(sp)
    80000b26:	6402                	ld	s0,0(sp)
    80000b28:	0141                	addi	sp,sp,16
    80000b2a:	8082                	ret

0000000080000b2c <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b2c:	1101                	addi	sp,sp,-32
    80000b2e:	ec06                	sd	ra,24(sp)
    80000b30:	e822                	sd	s0,16(sp)
    80000b32:	e426                	sd	s1,8(sp)
    80000b34:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b36:	00010517          	auipc	a0,0x10
    80000b3a:	01250513          	addi	a0,a0,18 # 80010b48 <kmem>
    80000b3e:	00000097          	auipc	ra,0x0
    80000b42:	0fe080e7          	jalr	254(ra) # 80000c3c <acquire>
  r = kmem.freelist;
    80000b46:	00010497          	auipc	s1,0x10
    80000b4a:	01a4b483          	ld	s1,26(s1) # 80010b60 <kmem+0x18>
  if (r)
    80000b4e:	c4b1                	beqz	s1,80000b9a <kalloc+0x6e>
  {
    kmem.freelist = r->next;
    80000b50:	609c                	ld	a5,0(s1)
    80000b52:	00010717          	auipc	a4,0x10
    80000b56:	00f73723          	sd	a5,14(a4) # 80010b60 <kmem+0x18>
    reference_count[(uint64)r / 4096] = 1; // initialize ref count to 1
    80000b5a:	00c4d793          	srli	a5,s1,0xc
    80000b5e:	00279713          	slli	a4,a5,0x2
    80000b62:	00010797          	auipc	a5,0x10
    80000b66:	00678793          	addi	a5,a5,6 # 80010b68 <reference_count>
    80000b6a:	97ba                	add	a5,a5,a4
    80000b6c:	4705                	li	a4,1
    80000b6e:	c398                	sw	a4,0(a5)
  }
  release(&kmem.lock);
    80000b70:	00010517          	auipc	a0,0x10
    80000b74:	fd850513          	addi	a0,a0,-40 # 80010b48 <kmem>
    80000b78:	00000097          	auipc	ra,0x0
    80000b7c:	178080e7          	jalr	376(ra) # 80000cf0 <release>

  if (r)
    memset((char *)r, 5, PGSIZE); // fill with junk
    80000b80:	6605                	lui	a2,0x1
    80000b82:	4595                	li	a1,5
    80000b84:	8526                	mv	a0,s1
    80000b86:	00000097          	auipc	ra,0x0
    80000b8a:	1b2080e7          	jalr	434(ra) # 80000d38 <memset>
  return (void *)r;
}
    80000b8e:	8526                	mv	a0,s1
    80000b90:	60e2                	ld	ra,24(sp)
    80000b92:	6442                	ld	s0,16(sp)
    80000b94:	64a2                	ld	s1,8(sp)
    80000b96:	6105                	addi	sp,sp,32
    80000b98:	8082                	ret
  release(&kmem.lock);
    80000b9a:	00010517          	auipc	a0,0x10
    80000b9e:	fae50513          	addi	a0,a0,-82 # 80010b48 <kmem>
    80000ba2:	00000097          	auipc	ra,0x0
    80000ba6:	14e080e7          	jalr	334(ra) # 80000cf0 <release>
  if (r)
    80000baa:	b7d5                	j	80000b8e <kalloc+0x62>

0000000080000bac <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bac:	1141                	addi	sp,sp,-16
    80000bae:	e422                	sd	s0,8(sp)
    80000bb0:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bb2:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bb4:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bb8:	00053823          	sd	zero,16(a0)
}
    80000bbc:	6422                	ld	s0,8(sp)
    80000bbe:	0141                	addi	sp,sp,16
    80000bc0:	8082                	ret

0000000080000bc2 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bc2:	411c                	lw	a5,0(a0)
    80000bc4:	e399                	bnez	a5,80000bca <holding+0x8>
    80000bc6:	4501                	li	a0,0
  return r;
}
    80000bc8:	8082                	ret
{
    80000bca:	1101                	addi	sp,sp,-32
    80000bcc:	ec06                	sd	ra,24(sp)
    80000bce:	e822                	sd	s0,16(sp)
    80000bd0:	e426                	sd	s1,8(sp)
    80000bd2:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bd4:	6904                	ld	s1,16(a0)
    80000bd6:	00001097          	auipc	ra,0x1
    80000bda:	eda080e7          	jalr	-294(ra) # 80001ab0 <mycpu>
    80000bde:	40a48533          	sub	a0,s1,a0
    80000be2:	00153513          	seqz	a0,a0
}
    80000be6:	60e2                	ld	ra,24(sp)
    80000be8:	6442                	ld	s0,16(sp)
    80000bea:	64a2                	ld	s1,8(sp)
    80000bec:	6105                	addi	sp,sp,32
    80000bee:	8082                	ret

0000000080000bf0 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bf0:	1101                	addi	sp,sp,-32
    80000bf2:	ec06                	sd	ra,24(sp)
    80000bf4:	e822                	sd	s0,16(sp)
    80000bf6:	e426                	sd	s1,8(sp)
    80000bf8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bfa:	100024f3          	csrr	s1,sstatus
    80000bfe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c02:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c04:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c08:	00001097          	auipc	ra,0x1
    80000c0c:	ea8080e7          	jalr	-344(ra) # 80001ab0 <mycpu>
    80000c10:	5d3c                	lw	a5,120(a0)
    80000c12:	cf89                	beqz	a5,80000c2c <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	e9c080e7          	jalr	-356(ra) # 80001ab0 <mycpu>
    80000c1c:	5d3c                	lw	a5,120(a0)
    80000c1e:	2785                	addiw	a5,a5,1
    80000c20:	dd3c                	sw	a5,120(a0)
}
    80000c22:	60e2                	ld	ra,24(sp)
    80000c24:	6442                	ld	s0,16(sp)
    80000c26:	64a2                	ld	s1,8(sp)
    80000c28:	6105                	addi	sp,sp,32
    80000c2a:	8082                	ret
    mycpu()->intena = old;
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	e84080e7          	jalr	-380(ra) # 80001ab0 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c34:	8085                	srli	s1,s1,0x1
    80000c36:	8885                	andi	s1,s1,1
    80000c38:	dd64                	sw	s1,124(a0)
    80000c3a:	bfe9                	j	80000c14 <push_off+0x24>

0000000080000c3c <acquire>:
{
    80000c3c:	1101                	addi	sp,sp,-32
    80000c3e:	ec06                	sd	ra,24(sp)
    80000c40:	e822                	sd	s0,16(sp)
    80000c42:	e426                	sd	s1,8(sp)
    80000c44:	1000                	addi	s0,sp,32
    80000c46:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c48:	00000097          	auipc	ra,0x0
    80000c4c:	fa8080e7          	jalr	-88(ra) # 80000bf0 <push_off>
  if(holding(lk))
    80000c50:	8526                	mv	a0,s1
    80000c52:	00000097          	auipc	ra,0x0
    80000c56:	f70080e7          	jalr	-144(ra) # 80000bc2 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c5a:	4705                	li	a4,1
  if(holding(lk))
    80000c5c:	e115                	bnez	a0,80000c80 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c5e:	87ba                	mv	a5,a4
    80000c60:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c64:	2781                	sext.w	a5,a5
    80000c66:	ffe5                	bnez	a5,80000c5e <acquire+0x22>
  __sync_synchronize();
    80000c68:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c6c:	00001097          	auipc	ra,0x1
    80000c70:	e44080e7          	jalr	-444(ra) # 80001ab0 <mycpu>
    80000c74:	e888                	sd	a0,16(s1)
}
    80000c76:	60e2                	ld	ra,24(sp)
    80000c78:	6442                	ld	s0,16(sp)
    80000c7a:	64a2                	ld	s1,8(sp)
    80000c7c:	6105                	addi	sp,sp,32
    80000c7e:	8082                	ret
    panic("acquire");
    80000c80:	00007517          	auipc	a0,0x7
    80000c84:	3f050513          	addi	a0,a0,1008 # 80008070 <digits+0x30>
    80000c88:	00000097          	auipc	ra,0x0
    80000c8c:	8b6080e7          	jalr	-1866(ra) # 8000053e <panic>

0000000080000c90 <pop_off>:

void
pop_off(void)
{
    80000c90:	1141                	addi	sp,sp,-16
    80000c92:	e406                	sd	ra,8(sp)
    80000c94:	e022                	sd	s0,0(sp)
    80000c96:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c98:	00001097          	auipc	ra,0x1
    80000c9c:	e18080e7          	jalr	-488(ra) # 80001ab0 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ca0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000ca4:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000ca6:	e78d                	bnez	a5,80000cd0 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000ca8:	5d3c                	lw	a5,120(a0)
    80000caa:	02f05b63          	blez	a5,80000ce0 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cae:	37fd                	addiw	a5,a5,-1
    80000cb0:	0007871b          	sext.w	a4,a5
    80000cb4:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cb6:	eb09                	bnez	a4,80000cc8 <pop_off+0x38>
    80000cb8:	5d7c                	lw	a5,124(a0)
    80000cba:	c799                	beqz	a5,80000cc8 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cbc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cc0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cc4:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cc8:	60a2                	ld	ra,8(sp)
    80000cca:	6402                	ld	s0,0(sp)
    80000ccc:	0141                	addi	sp,sp,16
    80000cce:	8082                	ret
    panic("pop_off - interruptible");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3a850513          	addi	a0,a0,936 # 80008078 <digits+0x38>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>
    panic("pop_off");
    80000ce0:	00007517          	auipc	a0,0x7
    80000ce4:	3b050513          	addi	a0,a0,944 # 80008090 <digits+0x50>
    80000ce8:	00000097          	auipc	ra,0x0
    80000cec:	856080e7          	jalr	-1962(ra) # 8000053e <panic>

0000000080000cf0 <release>:
{
    80000cf0:	1101                	addi	sp,sp,-32
    80000cf2:	ec06                	sd	ra,24(sp)
    80000cf4:	e822                	sd	s0,16(sp)
    80000cf6:	e426                	sd	s1,8(sp)
    80000cf8:	1000                	addi	s0,sp,32
    80000cfa:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cfc:	00000097          	auipc	ra,0x0
    80000d00:	ec6080e7          	jalr	-314(ra) # 80000bc2 <holding>
    80000d04:	c115                	beqz	a0,80000d28 <release+0x38>
  lk->cpu = 0;
    80000d06:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d0a:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d0e:	0f50000f          	fence	iorw,ow
    80000d12:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d16:	00000097          	auipc	ra,0x0
    80000d1a:	f7a080e7          	jalr	-134(ra) # 80000c90 <pop_off>
}
    80000d1e:	60e2                	ld	ra,24(sp)
    80000d20:	6442                	ld	s0,16(sp)
    80000d22:	64a2                	ld	s1,8(sp)
    80000d24:	6105                	addi	sp,sp,32
    80000d26:	8082                	ret
    panic("release");
    80000d28:	00007517          	auipc	a0,0x7
    80000d2c:	37050513          	addi	a0,a0,880 # 80008098 <digits+0x58>
    80000d30:	00000097          	auipc	ra,0x0
    80000d34:	80e080e7          	jalr	-2034(ra) # 8000053e <panic>

0000000080000d38 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d38:	1141                	addi	sp,sp,-16
    80000d3a:	e422                	sd	s0,8(sp)
    80000d3c:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d3e:	ca19                	beqz	a2,80000d54 <memset+0x1c>
    80000d40:	87aa                	mv	a5,a0
    80000d42:	1602                	slli	a2,a2,0x20
    80000d44:	9201                	srli	a2,a2,0x20
    80000d46:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d4a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d4e:	0785                	addi	a5,a5,1
    80000d50:	fee79de3          	bne	a5,a4,80000d4a <memset+0x12>
  }
  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret

0000000080000d5a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d5a:	1141                	addi	sp,sp,-16
    80000d5c:	e422                	sd	s0,8(sp)
    80000d5e:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d60:	ca05                	beqz	a2,80000d90 <memcmp+0x36>
    80000d62:	fff6069b          	addiw	a3,a2,-1
    80000d66:	1682                	slli	a3,a3,0x20
    80000d68:	9281                	srli	a3,a3,0x20
    80000d6a:	0685                	addi	a3,a3,1
    80000d6c:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d6e:	00054783          	lbu	a5,0(a0)
    80000d72:	0005c703          	lbu	a4,0(a1)
    80000d76:	00e79863          	bne	a5,a4,80000d86 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d7a:	0505                	addi	a0,a0,1
    80000d7c:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d7e:	fed518e3          	bne	a0,a3,80000d6e <memcmp+0x14>
  }

  return 0;
    80000d82:	4501                	li	a0,0
    80000d84:	a019                	j	80000d8a <memcmp+0x30>
      return *s1 - *s2;
    80000d86:	40e7853b          	subw	a0,a5,a4
}
    80000d8a:	6422                	ld	s0,8(sp)
    80000d8c:	0141                	addi	sp,sp,16
    80000d8e:	8082                	ret
  return 0;
    80000d90:	4501                	li	a0,0
    80000d92:	bfe5                	j	80000d8a <memcmp+0x30>

0000000080000d94 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d94:	1141                	addi	sp,sp,-16
    80000d96:	e422                	sd	s0,8(sp)
    80000d98:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d9a:	c205                	beqz	a2,80000dba <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d9c:	02a5e263          	bltu	a1,a0,80000dc0 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000da0:	1602                	slli	a2,a2,0x20
    80000da2:	9201                	srli	a2,a2,0x20
    80000da4:	00c587b3          	add	a5,a1,a2
{
    80000da8:	872a                	mv	a4,a0
      *d++ = *s++;
    80000daa:	0585                	addi	a1,a1,1
    80000dac:	0705                	addi	a4,a4,1
    80000dae:	fff5c683          	lbu	a3,-1(a1)
    80000db2:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000db6:	fef59ae3          	bne	a1,a5,80000daa <memmove+0x16>

  return dst;
}
    80000dba:	6422                	ld	s0,8(sp)
    80000dbc:	0141                	addi	sp,sp,16
    80000dbe:	8082                	ret
  if(s < d && s + n > d){
    80000dc0:	02061693          	slli	a3,a2,0x20
    80000dc4:	9281                	srli	a3,a3,0x20
    80000dc6:	00d58733          	add	a4,a1,a3
    80000dca:	fce57be3          	bgeu	a0,a4,80000da0 <memmove+0xc>
    d += n;
    80000dce:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000dd0:	fff6079b          	addiw	a5,a2,-1
    80000dd4:	1782                	slli	a5,a5,0x20
    80000dd6:	9381                	srli	a5,a5,0x20
    80000dd8:	fff7c793          	not	a5,a5
    80000ddc:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dde:	177d                	addi	a4,a4,-1
    80000de0:	16fd                	addi	a3,a3,-1
    80000de2:	00074603          	lbu	a2,0(a4)
    80000de6:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000dea:	fee79ae3          	bne	a5,a4,80000dde <memmove+0x4a>
    80000dee:	b7f1                	j	80000dba <memmove+0x26>

0000000080000df0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000df0:	1141                	addi	sp,sp,-16
    80000df2:	e406                	sd	ra,8(sp)
    80000df4:	e022                	sd	s0,0(sp)
    80000df6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000df8:	00000097          	auipc	ra,0x0
    80000dfc:	f9c080e7          	jalr	-100(ra) # 80000d94 <memmove>
}
    80000e00:	60a2                	ld	ra,8(sp)
    80000e02:	6402                	ld	s0,0(sp)
    80000e04:	0141                	addi	sp,sp,16
    80000e06:	8082                	ret

0000000080000e08 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e08:	1141                	addi	sp,sp,-16
    80000e0a:	e422                	sd	s0,8(sp)
    80000e0c:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e0e:	ce11                	beqz	a2,80000e2a <strncmp+0x22>
    80000e10:	00054783          	lbu	a5,0(a0)
    80000e14:	cf89                	beqz	a5,80000e2e <strncmp+0x26>
    80000e16:	0005c703          	lbu	a4,0(a1)
    80000e1a:	00f71a63          	bne	a4,a5,80000e2e <strncmp+0x26>
    n--, p++, q++;
    80000e1e:	367d                	addiw	a2,a2,-1
    80000e20:	0505                	addi	a0,a0,1
    80000e22:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e24:	f675                	bnez	a2,80000e10 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e26:	4501                	li	a0,0
    80000e28:	a809                	j	80000e3a <strncmp+0x32>
    80000e2a:	4501                	li	a0,0
    80000e2c:	a039                	j	80000e3a <strncmp+0x32>
  if(n == 0)
    80000e2e:	ca09                	beqz	a2,80000e40 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e30:	00054503          	lbu	a0,0(a0)
    80000e34:	0005c783          	lbu	a5,0(a1)
    80000e38:	9d1d                	subw	a0,a0,a5
}
    80000e3a:	6422                	ld	s0,8(sp)
    80000e3c:	0141                	addi	sp,sp,16
    80000e3e:	8082                	ret
    return 0;
    80000e40:	4501                	li	a0,0
    80000e42:	bfe5                	j	80000e3a <strncmp+0x32>

0000000080000e44 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e44:	1141                	addi	sp,sp,-16
    80000e46:	e422                	sd	s0,8(sp)
    80000e48:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e4a:	872a                	mv	a4,a0
    80000e4c:	8832                	mv	a6,a2
    80000e4e:	367d                	addiw	a2,a2,-1
    80000e50:	01005963          	blez	a6,80000e62 <strncpy+0x1e>
    80000e54:	0705                	addi	a4,a4,1
    80000e56:	0005c783          	lbu	a5,0(a1)
    80000e5a:	fef70fa3          	sb	a5,-1(a4)
    80000e5e:	0585                	addi	a1,a1,1
    80000e60:	f7f5                	bnez	a5,80000e4c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e62:	86ba                	mv	a3,a4
    80000e64:	00c05c63          	blez	a2,80000e7c <strncpy+0x38>
    *s++ = 0;
    80000e68:	0685                	addi	a3,a3,1
    80000e6a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e6e:	fff6c793          	not	a5,a3
    80000e72:	9fb9                	addw	a5,a5,a4
    80000e74:	010787bb          	addw	a5,a5,a6
    80000e78:	fef048e3          	bgtz	a5,80000e68 <strncpy+0x24>
  return os;
}
    80000e7c:	6422                	ld	s0,8(sp)
    80000e7e:	0141                	addi	sp,sp,16
    80000e80:	8082                	ret

0000000080000e82 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e82:	1141                	addi	sp,sp,-16
    80000e84:	e422                	sd	s0,8(sp)
    80000e86:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e88:	02c05363          	blez	a2,80000eae <safestrcpy+0x2c>
    80000e8c:	fff6069b          	addiw	a3,a2,-1
    80000e90:	1682                	slli	a3,a3,0x20
    80000e92:	9281                	srli	a3,a3,0x20
    80000e94:	96ae                	add	a3,a3,a1
    80000e96:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e98:	00d58963          	beq	a1,a3,80000eaa <safestrcpy+0x28>
    80000e9c:	0585                	addi	a1,a1,1
    80000e9e:	0785                	addi	a5,a5,1
    80000ea0:	fff5c703          	lbu	a4,-1(a1)
    80000ea4:	fee78fa3          	sb	a4,-1(a5)
    80000ea8:	fb65                	bnez	a4,80000e98 <safestrcpy+0x16>
    ;
  *s = 0;
    80000eaa:	00078023          	sb	zero,0(a5)
  return os;
}
    80000eae:	6422                	ld	s0,8(sp)
    80000eb0:	0141                	addi	sp,sp,16
    80000eb2:	8082                	ret

0000000080000eb4 <strlen>:

int
strlen(const char *s)
{
    80000eb4:	1141                	addi	sp,sp,-16
    80000eb6:	e422                	sd	s0,8(sp)
    80000eb8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000eba:	00054783          	lbu	a5,0(a0)
    80000ebe:	cf91                	beqz	a5,80000eda <strlen+0x26>
    80000ec0:	0505                	addi	a0,a0,1
    80000ec2:	87aa                	mv	a5,a0
    80000ec4:	4685                	li	a3,1
    80000ec6:	9e89                	subw	a3,a3,a0
    80000ec8:	00f6853b          	addw	a0,a3,a5
    80000ecc:	0785                	addi	a5,a5,1
    80000ece:	fff7c703          	lbu	a4,-1(a5)
    80000ed2:	fb7d                	bnez	a4,80000ec8 <strlen+0x14>
    ;
  return n;
}
    80000ed4:	6422                	ld	s0,8(sp)
    80000ed6:	0141                	addi	sp,sp,16
    80000ed8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eda:	4501                	li	a0,0
    80000edc:	bfe5                	j	80000ed4 <strlen+0x20>

0000000080000ede <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ede:	1141                	addi	sp,sp,-16
    80000ee0:	e406                	sd	ra,8(sp)
    80000ee2:	e022                	sd	s0,0(sp)
    80000ee4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ee6:	00001097          	auipc	ra,0x1
    80000eea:	bba080e7          	jalr	-1094(ra) # 80001aa0 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eee:	00008717          	auipc	a4,0x8
    80000ef2:	9da70713          	addi	a4,a4,-1574 # 800088c8 <started>
  if(cpuid() == 0){
    80000ef6:	c139                	beqz	a0,80000f3c <main+0x5e>
    while(started == 0)
    80000ef8:	431c                	lw	a5,0(a4)
    80000efa:	2781                	sext.w	a5,a5
    80000efc:	dff5                	beqz	a5,80000ef8 <main+0x1a>
      ;
    __sync_synchronize();
    80000efe:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f02:	00001097          	auipc	ra,0x1
    80000f06:	b9e080e7          	jalr	-1122(ra) # 80001aa0 <cpuid>
    80000f0a:	85aa                	mv	a1,a0
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	1ac50513          	addi	a0,a0,428 # 800080b8 <digits+0x78>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000f1c:	00000097          	auipc	ra,0x0
    80000f20:	0d8080e7          	jalr	216(ra) # 80000ff4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f24:	00002097          	auipc	ra,0x2
    80000f28:	dac080e7          	jalr	-596(ra) # 80002cd0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f2c:	00005097          	auipc	ra,0x5
    80000f30:	5b4080e7          	jalr	1460(ra) # 800064e0 <plicinithart>
  }

  scheduler();        
    80000f34:	00001097          	auipc	ra,0x1
    80000f38:	0d4080e7          	jalr	212(ra) # 80002008 <scheduler>
    consoleinit();
    80000f3c:	fffff097          	auipc	ra,0xfffff
    80000f40:	514080e7          	jalr	1300(ra) # 80000450 <consoleinit>
    printfinit();
    80000f44:	00000097          	auipc	ra,0x0
    80000f48:	824080e7          	jalr	-2012(ra) # 80000768 <printfinit>
    printf("\n");
    80000f4c:	00007517          	auipc	a0,0x7
    80000f50:	17c50513          	addi	a0,a0,380 # 800080c8 <digits+0x88>
    80000f54:	fffff097          	auipc	ra,0xfffff
    80000f58:	634080e7          	jalr	1588(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f5c:	00007517          	auipc	a0,0x7
    80000f60:	14450513          	addi	a0,a0,324 # 800080a0 <digits+0x60>
    80000f64:	fffff097          	auipc	ra,0xfffff
    80000f68:	624080e7          	jalr	1572(ra) # 80000588 <printf>
    printf("\n");
    80000f6c:	00007517          	auipc	a0,0x7
    80000f70:	15c50513          	addi	a0,a0,348 # 800080c8 <digits+0x88>
    80000f74:	fffff097          	auipc	ra,0xfffff
    80000f78:	614080e7          	jalr	1556(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f7c:	00000097          	auipc	ra,0x0
    80000f80:	b74080e7          	jalr	-1164(ra) # 80000af0 <kinit>
    kvminit();       // create kernel page table
    80000f84:	00000097          	auipc	ra,0x0
    80000f88:	326080e7          	jalr	806(ra) # 800012aa <kvminit>
    kvminithart();   // turn on paging
    80000f8c:	00000097          	auipc	ra,0x0
    80000f90:	068080e7          	jalr	104(ra) # 80000ff4 <kvminithart>
    procinit();      // process table
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	a58080e7          	jalr	-1448(ra) # 800019ec <procinit>
    trapinit();      // trap vectors
    80000f9c:	00002097          	auipc	ra,0x2
    80000fa0:	d0c080e7          	jalr	-756(ra) # 80002ca8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	d2c080e7          	jalr	-724(ra) # 80002cd0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fac:	00005097          	auipc	ra,0x5
    80000fb0:	51e080e7          	jalr	1310(ra) # 800064ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fb4:	00005097          	auipc	ra,0x5
    80000fb8:	52c080e7          	jalr	1324(ra) # 800064e0 <plicinithart>
    binit();         // buffer cache
    80000fbc:	00002097          	auipc	ra,0x2
    80000fc0:	5d2080e7          	jalr	1490(ra) # 8000358e <binit>
    iinit();         // inode table
    80000fc4:	00003097          	auipc	ra,0x3
    80000fc8:	c76080e7          	jalr	-906(ra) # 80003c3a <iinit>
    fileinit();      // file table
    80000fcc:	00004097          	auipc	ra,0x4
    80000fd0:	c14080e7          	jalr	-1004(ra) # 80004be0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fd4:	00005097          	auipc	ra,0x5
    80000fd8:	614080e7          	jalr	1556(ra) # 800065e8 <virtio_disk_init>
    userinit();      // first user process
    80000fdc:	00001097          	auipc	ra,0x1
    80000fe0:	e0e080e7          	jalr	-498(ra) # 80001dea <userinit>
    __sync_synchronize();
    80000fe4:	0ff0000f          	fence
    started = 1;
    80000fe8:	4785                	li	a5,1
    80000fea:	00008717          	auipc	a4,0x8
    80000fee:	8cf72f23          	sw	a5,-1826(a4) # 800088c8 <started>
    80000ff2:	b789                	j	80000f34 <main+0x56>

0000000080000ff4 <kvminithart>:
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void kvminithart()
{
    80000ff4:	1141                	addi	sp,sp,-16
    80000ff6:	e422                	sd	s0,8(sp)
    80000ff8:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ffa:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000ffe:	00008797          	auipc	a5,0x8
    80001002:	8d27b783          	ld	a5,-1838(a5) # 800088d0 <kernel_pagetable>
    80001006:	83b1                	srli	a5,a5,0xc
    80001008:	577d                	li	a4,-1
    8000100a:	177e                	slli	a4,a4,0x3f
    8000100c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000100e:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001012:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001016:	6422                	ld	s0,8(sp)
    80001018:	0141                	addi	sp,sp,16
    8000101a:	8082                	ret

000000008000101c <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000101c:	7139                	addi	sp,sp,-64
    8000101e:	fc06                	sd	ra,56(sp)
    80001020:	f822                	sd	s0,48(sp)
    80001022:	f426                	sd	s1,40(sp)
    80001024:	f04a                	sd	s2,32(sp)
    80001026:	ec4e                	sd	s3,24(sp)
    80001028:	e852                	sd	s4,16(sp)
    8000102a:	e456                	sd	s5,8(sp)
    8000102c:	e05a                	sd	s6,0(sp)
    8000102e:	0080                	addi	s0,sp,64
    80001030:	84aa                	mv	s1,a0
    80001032:	89ae                	mv	s3,a1
    80001034:	8ab2                	mv	s5,a2
  if (va >= MAXVA)
    80001036:	57fd                	li	a5,-1
    80001038:	83e9                	srli	a5,a5,0x1a
    8000103a:	4a79                	li	s4,30
    panic("walk");

  for (int level = 2; level > 0; level--)
    8000103c:	4b31                	li	s6,12
  if (va >= MAXVA)
    8000103e:	04b7f263          	bgeu	a5,a1,80001082 <walk+0x66>
    panic("walk");
    80001042:	00007517          	auipc	a0,0x7
    80001046:	08e50513          	addi	a0,a0,142 # 800080d0 <digits+0x90>
    8000104a:	fffff097          	auipc	ra,0xfffff
    8000104e:	4f4080e7          	jalr	1268(ra) # 8000053e <panic>
    {
      pagetable = (pagetable_t)PTE2PA(*pte);
    }
    else
    {
      if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
    80001052:	060a8663          	beqz	s5,800010be <walk+0xa2>
    80001056:	00000097          	auipc	ra,0x0
    8000105a:	ad6080e7          	jalr	-1322(ra) # 80000b2c <kalloc>
    8000105e:	84aa                	mv	s1,a0
    80001060:	c529                	beqz	a0,800010aa <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001062:	6605                	lui	a2,0x1
    80001064:	4581                	li	a1,0
    80001066:	00000097          	auipc	ra,0x0
    8000106a:	cd2080e7          	jalr	-814(ra) # 80000d38 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000106e:	00c4d793          	srli	a5,s1,0xc
    80001072:	07aa                	slli	a5,a5,0xa
    80001074:	0017e793          	ori	a5,a5,1
    80001078:	00f93023          	sd	a5,0(s2)
  for (int level = 2; level > 0; level--)
    8000107c:	3a5d                	addiw	s4,s4,-9
    8000107e:	036a0063          	beq	s4,s6,8000109e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001082:	0149d933          	srl	s2,s3,s4
    80001086:	1ff97913          	andi	s2,s2,511
    8000108a:	090e                	slli	s2,s2,0x3
    8000108c:	9926                	add	s2,s2,s1
    if (*pte & PTE_V)
    8000108e:	00093483          	ld	s1,0(s2)
    80001092:	0014f793          	andi	a5,s1,1
    80001096:	dfd5                	beqz	a5,80001052 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001098:	80a9                	srli	s1,s1,0xa
    8000109a:	04b2                	slli	s1,s1,0xc
    8000109c:	b7c5                	j	8000107c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000109e:	00c9d513          	srli	a0,s3,0xc
    800010a2:	1ff57513          	andi	a0,a0,511
    800010a6:	050e                	slli	a0,a0,0x3
    800010a8:	9526                	add	a0,a0,s1
}
    800010aa:	70e2                	ld	ra,56(sp)
    800010ac:	7442                	ld	s0,48(sp)
    800010ae:	74a2                	ld	s1,40(sp)
    800010b0:	7902                	ld	s2,32(sp)
    800010b2:	69e2                	ld	s3,24(sp)
    800010b4:	6a42                	ld	s4,16(sp)
    800010b6:	6aa2                	ld	s5,8(sp)
    800010b8:	6b02                	ld	s6,0(sp)
    800010ba:	6121                	addi	sp,sp,64
    800010bc:	8082                	ret
        return 0;
    800010be:	4501                	li	a0,0
    800010c0:	b7ed                	j	800010aa <walk+0x8e>

00000000800010c2 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    800010c2:	57fd                	li	a5,-1
    800010c4:	83e9                	srli	a5,a5,0x1a
    800010c6:	00b7f463          	bgeu	a5,a1,800010ce <walkaddr+0xc>
    return 0;
    800010ca:	4501                	li	a0,0
    return 0;
  if ((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010cc:	8082                	ret
{
    800010ce:	1141                	addi	sp,sp,-16
    800010d0:	e406                	sd	ra,8(sp)
    800010d2:	e022                	sd	s0,0(sp)
    800010d4:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010d6:	4601                	li	a2,0
    800010d8:	00000097          	auipc	ra,0x0
    800010dc:	f44080e7          	jalr	-188(ra) # 8000101c <walk>
  if (pte == 0)
    800010e0:	c105                	beqz	a0,80001100 <walkaddr+0x3e>
  if ((*pte & PTE_V) == 0)
    800010e2:	611c                	ld	a5,0(a0)
  if ((*pte & PTE_U) == 0)
    800010e4:	0117f693          	andi	a3,a5,17
    800010e8:	4745                	li	a4,17
    return 0;
    800010ea:	4501                	li	a0,0
  if ((*pte & PTE_U) == 0)
    800010ec:	00e68663          	beq	a3,a4,800010f8 <walkaddr+0x36>
}
    800010f0:	60a2                	ld	ra,8(sp)
    800010f2:	6402                	ld	s0,0(sp)
    800010f4:	0141                	addi	sp,sp,16
    800010f6:	8082                	ret
  pa = PTE2PA(*pte);
    800010f8:	00a7d513          	srli	a0,a5,0xa
    800010fc:	0532                	slli	a0,a0,0xc
  return pa;
    800010fe:	bfcd                	j	800010f0 <walkaddr+0x2e>
    return 0;
    80001100:	4501                	li	a0,0
    80001102:	b7fd                	j	800010f0 <walkaddr+0x2e>

0000000080001104 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001104:	715d                	addi	sp,sp,-80
    80001106:	e486                	sd	ra,72(sp)
    80001108:	e0a2                	sd	s0,64(sp)
    8000110a:	fc26                	sd	s1,56(sp)
    8000110c:	f84a                	sd	s2,48(sp)
    8000110e:	f44e                	sd	s3,40(sp)
    80001110:	f052                	sd	s4,32(sp)
    80001112:	ec56                	sd	s5,24(sp)
    80001114:	e85a                	sd	s6,16(sp)
    80001116:	e45e                	sd	s7,8(sp)
    80001118:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if (size == 0)
    8000111a:	c639                	beqz	a2,80001168 <mappages+0x64>
    8000111c:	8aaa                	mv	s5,a0
    8000111e:	8b3a                	mv	s6,a4
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    80001120:	77fd                	lui	a5,0xfffff
    80001122:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001126:	15fd                	addi	a1,a1,-1
    80001128:	00c589b3          	add	s3,a1,a2
    8000112c:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001130:	8952                	mv	s2,s4
    80001132:	41468a33          	sub	s4,a3,s4
    if (*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if (a == last)
      break;
    a += PGSIZE;
    80001136:	6b85                	lui	s7,0x1
    80001138:	012a04b3          	add	s1,s4,s2
    if ((pte = walk(pagetable, a, 1)) == 0)
    8000113c:	4605                	li	a2,1
    8000113e:	85ca                	mv	a1,s2
    80001140:	8556                	mv	a0,s5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	eda080e7          	jalr	-294(ra) # 8000101c <walk>
    8000114a:	cd1d                	beqz	a0,80001188 <mappages+0x84>
    if (*pte & PTE_V)
    8000114c:	611c                	ld	a5,0(a0)
    8000114e:	8b85                	andi	a5,a5,1
    80001150:	e785                	bnez	a5,80001178 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001152:	80b1                	srli	s1,s1,0xc
    80001154:	04aa                	slli	s1,s1,0xa
    80001156:	0164e4b3          	or	s1,s1,s6
    8000115a:	0014e493          	ori	s1,s1,1
    8000115e:	e104                	sd	s1,0(a0)
    if (a == last)
    80001160:	05390063          	beq	s2,s3,800011a0 <mappages+0x9c>
    a += PGSIZE;
    80001164:	995e                	add	s2,s2,s7
    if ((pte = walk(pagetable, a, 1)) == 0)
    80001166:	bfc9                	j	80001138 <mappages+0x34>
    panic("mappages: size");
    80001168:	00007517          	auipc	a0,0x7
    8000116c:	f7050513          	addi	a0,a0,-144 # 800080d8 <digits+0x98>
    80001170:	fffff097          	auipc	ra,0xfffff
    80001174:	3ce080e7          	jalr	974(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f7050513          	addi	a0,a0,-144 # 800080e8 <digits+0xa8>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3be080e7          	jalr	958(ra) # 8000053e <panic>
      return -1;
    80001188:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000118a:	60a6                	ld	ra,72(sp)
    8000118c:	6406                	ld	s0,64(sp)
    8000118e:	74e2                	ld	s1,56(sp)
    80001190:	7942                	ld	s2,48(sp)
    80001192:	79a2                	ld	s3,40(sp)
    80001194:	7a02                	ld	s4,32(sp)
    80001196:	6ae2                	ld	s5,24(sp)
    80001198:	6b42                	ld	s6,16(sp)
    8000119a:	6ba2                	ld	s7,8(sp)
    8000119c:	6161                	addi	sp,sp,80
    8000119e:	8082                	ret
  return 0;
    800011a0:	4501                	li	a0,0
    800011a2:	b7e5                	j	8000118a <mappages+0x86>

00000000800011a4 <kvmmap>:
{
    800011a4:	1141                	addi	sp,sp,-16
    800011a6:	e406                	sd	ra,8(sp)
    800011a8:	e022                	sd	s0,0(sp)
    800011aa:	0800                	addi	s0,sp,16
    800011ac:	87b6                	mv	a5,a3
  if (mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011ae:	86b2                	mv	a3,a2
    800011b0:	863e                	mv	a2,a5
    800011b2:	00000097          	auipc	ra,0x0
    800011b6:	f52080e7          	jalr	-174(ra) # 80001104 <mappages>
    800011ba:	e509                	bnez	a0,800011c4 <kvmmap+0x20>
}
    800011bc:	60a2                	ld	ra,8(sp)
    800011be:	6402                	ld	s0,0(sp)
    800011c0:	0141                	addi	sp,sp,16
    800011c2:	8082                	ret
    panic("kvmmap");
    800011c4:	00007517          	auipc	a0,0x7
    800011c8:	f3450513          	addi	a0,a0,-204 # 800080f8 <digits+0xb8>
    800011cc:	fffff097          	auipc	ra,0xfffff
    800011d0:	372080e7          	jalr	882(ra) # 8000053e <panic>

00000000800011d4 <kvmmake>:
{
    800011d4:	1101                	addi	sp,sp,-32
    800011d6:	ec06                	sd	ra,24(sp)
    800011d8:	e822                	sd	s0,16(sp)
    800011da:	e426                	sd	s1,8(sp)
    800011dc:	e04a                	sd	s2,0(sp)
    800011de:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t)kalloc();
    800011e0:	00000097          	auipc	ra,0x0
    800011e4:	94c080e7          	jalr	-1716(ra) # 80000b2c <kalloc>
    800011e8:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011ea:	6605                	lui	a2,0x1
    800011ec:	4581                	li	a1,0
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	b4a080e7          	jalr	-1206(ra) # 80000d38 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	6685                	lui	a3,0x1
    800011fa:	10000637          	lui	a2,0x10000
    800011fe:	100005b7          	lui	a1,0x10000
    80001202:	8526                	mv	a0,s1
    80001204:	00000097          	auipc	ra,0x0
    80001208:	fa0080e7          	jalr	-96(ra) # 800011a4 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000120c:	4719                	li	a4,6
    8000120e:	6685                	lui	a3,0x1
    80001210:	10001637          	lui	a2,0x10001
    80001214:	100015b7          	lui	a1,0x10001
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f8a080e7          	jalr	-118(ra) # 800011a4 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001222:	4719                	li	a4,6
    80001224:	004006b7          	lui	a3,0x400
    80001228:	0c000637          	lui	a2,0xc000
    8000122c:	0c0005b7          	lui	a1,0xc000
    80001230:	8526                	mv	a0,s1
    80001232:	00000097          	auipc	ra,0x0
    80001236:	f72080e7          	jalr	-142(ra) # 800011a4 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    8000123a:	00007917          	auipc	s2,0x7
    8000123e:	dc690913          	addi	s2,s2,-570 # 80008000 <etext>
    80001242:	4729                	li	a4,10
    80001244:	80007697          	auipc	a3,0x80007
    80001248:	dbc68693          	addi	a3,a3,-580 # 8000 <_entry-0x7fff8000>
    8000124c:	4605                	li	a2,1
    8000124e:	067e                	slli	a2,a2,0x1f
    80001250:	85b2                	mv	a1,a2
    80001252:	8526                	mv	a0,s1
    80001254:	00000097          	auipc	ra,0x0
    80001258:	f50080e7          	jalr	-176(ra) # 800011a4 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    8000125c:	4719                	li	a4,6
    8000125e:	46c5                	li	a3,17
    80001260:	06ee                	slli	a3,a3,0x1b
    80001262:	412686b3          	sub	a3,a3,s2
    80001266:	864a                	mv	a2,s2
    80001268:	85ca                	mv	a1,s2
    8000126a:	8526                	mv	a0,s1
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	f38080e7          	jalr	-200(ra) # 800011a4 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001274:	4729                	li	a4,10
    80001276:	6685                	lui	a3,0x1
    80001278:	00006617          	auipc	a2,0x6
    8000127c:	d8860613          	addi	a2,a2,-632 # 80007000 <_trampoline>
    80001280:	040005b7          	lui	a1,0x4000
    80001284:	15fd                	addi	a1,a1,-1
    80001286:	05b2                	slli	a1,a1,0xc
    80001288:	8526                	mv	a0,s1
    8000128a:	00000097          	auipc	ra,0x0
    8000128e:	f1a080e7          	jalr	-230(ra) # 800011a4 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001292:	8526                	mv	a0,s1
    80001294:	00000097          	auipc	ra,0x0
    80001298:	6c2080e7          	jalr	1730(ra) # 80001956 <proc_mapstacks>
}
    8000129c:	8526                	mv	a0,s1
    8000129e:	60e2                	ld	ra,24(sp)
    800012a0:	6442                	ld	s0,16(sp)
    800012a2:	64a2                	ld	s1,8(sp)
    800012a4:	6902                	ld	s2,0(sp)
    800012a6:	6105                	addi	sp,sp,32
    800012a8:	8082                	ret

00000000800012aa <kvminit>:
{
    800012aa:	1141                	addi	sp,sp,-16
    800012ac:	e406                	sd	ra,8(sp)
    800012ae:	e022                	sd	s0,0(sp)
    800012b0:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012b2:	00000097          	auipc	ra,0x0
    800012b6:	f22080e7          	jalr	-222(ra) # 800011d4 <kvmmake>
    800012ba:	00007797          	auipc	a5,0x7
    800012be:	60a7bb23          	sd	a0,1558(a5) # 800088d0 <kernel_pagetable>
}
    800012c2:	60a2                	ld	ra,8(sp)
    800012c4:	6402                	ld	s0,0(sp)
    800012c6:	0141                	addi	sp,sp,16
    800012c8:	8082                	ret

00000000800012ca <uvmunmap>:

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012ca:	715d                	addi	sp,sp,-80
    800012cc:	e486                	sd	ra,72(sp)
    800012ce:	e0a2                	sd	s0,64(sp)
    800012d0:	fc26                	sd	s1,56(sp)
    800012d2:	f84a                	sd	s2,48(sp)
    800012d4:	f44e                	sd	s3,40(sp)
    800012d6:	f052                	sd	s4,32(sp)
    800012d8:	ec56                	sd	s5,24(sp)
    800012da:	e85a                	sd	s6,16(sp)
    800012dc:	e45e                	sd	s7,8(sp)
    800012de:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if ((va % PGSIZE) != 0)
    800012e0:	03459793          	slli	a5,a1,0x34
    800012e4:	e795                	bnez	a5,80001310 <uvmunmap+0x46>
    800012e6:	8a2a                	mv	s4,a0
    800012e8:	892e                	mv	s2,a1
    800012ea:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    800012ec:	0632                	slli	a2,a2,0xc
    800012ee:	00b609b3          	add	s3,a2,a1
  {
    if ((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if ((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if (PTE_FLAGS(*pte) == PTE_V)
    800012f2:	4b85                	li	s7,1
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    800012f4:	6b05                	lui	s6,0x1
    800012f6:	0735e263          	bltu	a1,s3,8000135a <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void *)pa);
    }
    *pte = 0;
  }
}
    800012fa:	60a6                	ld	ra,72(sp)
    800012fc:	6406                	ld	s0,64(sp)
    800012fe:	74e2                	ld	s1,56(sp)
    80001300:	7942                	ld	s2,48(sp)
    80001302:	79a2                	ld	s3,40(sp)
    80001304:	7a02                	ld	s4,32(sp)
    80001306:	6ae2                	ld	s5,24(sp)
    80001308:	6b42                	ld	s6,16(sp)
    8000130a:	6ba2                	ld	s7,8(sp)
    8000130c:	6161                	addi	sp,sp,80
    8000130e:	8082                	ret
    panic("uvmunmap: not aligned");
    80001310:	00007517          	auipc	a0,0x7
    80001314:	df050513          	addi	a0,a0,-528 # 80008100 <digits+0xc0>
    80001318:	fffff097          	auipc	ra,0xfffff
    8000131c:	226080e7          	jalr	550(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    80001320:	00007517          	auipc	a0,0x7
    80001324:	df850513          	addi	a0,a0,-520 # 80008118 <digits+0xd8>
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	216080e7          	jalr	534(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    80001330:	00007517          	auipc	a0,0x7
    80001334:	df850513          	addi	a0,a0,-520 # 80008128 <digits+0xe8>
    80001338:	fffff097          	auipc	ra,0xfffff
    8000133c:	206080e7          	jalr	518(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    80001340:	00007517          	auipc	a0,0x7
    80001344:	e0050513          	addi	a0,a0,-512 # 80008140 <digits+0x100>
    80001348:	fffff097          	auipc	ra,0xfffff
    8000134c:	1f6080e7          	jalr	502(ra) # 8000053e <panic>
    *pte = 0;
    80001350:	0004b023          	sd	zero,0(s1)
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001354:	995a                	add	s2,s2,s6
    80001356:	fb3972e3          	bgeu	s2,s3,800012fa <uvmunmap+0x30>
    if ((pte = walk(pagetable, a, 0)) == 0)
    8000135a:	4601                	li	a2,0
    8000135c:	85ca                	mv	a1,s2
    8000135e:	8552                	mv	a0,s4
    80001360:	00000097          	auipc	ra,0x0
    80001364:	cbc080e7          	jalr	-836(ra) # 8000101c <walk>
    80001368:	84aa                	mv	s1,a0
    8000136a:	d95d                	beqz	a0,80001320 <uvmunmap+0x56>
    if ((*pte & PTE_V) == 0)
    8000136c:	6108                	ld	a0,0(a0)
    8000136e:	00157793          	andi	a5,a0,1
    80001372:	dfdd                	beqz	a5,80001330 <uvmunmap+0x66>
    if (PTE_FLAGS(*pte) == PTE_V)
    80001374:	3ff57793          	andi	a5,a0,1023
    80001378:	fd7784e3          	beq	a5,s7,80001340 <uvmunmap+0x76>
    if (do_free)
    8000137c:	fc0a8ae3          	beqz	s5,80001350 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001380:	8129                	srli	a0,a0,0xa
      kfree((void *)pa);
    80001382:	0532                	slli	a0,a0,0xc
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	666080e7          	jalr	1638(ra) # 800009ea <kfree>
    8000138c:	b7d1                	j	80001350 <uvmunmap+0x86>

000000008000138e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000138e:	1101                	addi	sp,sp,-32
    80001390:	ec06                	sd	ra,24(sp)
    80001392:	e822                	sd	s0,16(sp)
    80001394:	e426                	sd	s1,8(sp)
    80001396:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t)kalloc();
    80001398:	fffff097          	auipc	ra,0xfffff
    8000139c:	794080e7          	jalr	1940(ra) # 80000b2c <kalloc>
    800013a0:	84aa                	mv	s1,a0
  if (pagetable == 0)
    800013a2:	c519                	beqz	a0,800013b0 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013a4:	6605                	lui	a2,0x1
    800013a6:	4581                	li	a1,0
    800013a8:	00000097          	auipc	ra,0x0
    800013ac:	990080e7          	jalr	-1648(ra) # 80000d38 <memset>
  return pagetable;
}
    800013b0:	8526                	mv	a0,s1
    800013b2:	60e2                	ld	ra,24(sp)
    800013b4:	6442                	ld	s0,16(sp)
    800013b6:	64a2                	ld	s1,8(sp)
    800013b8:	6105                	addi	sp,sp,32
    800013ba:	8082                	ret

00000000800013bc <uvmfirst>:

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013bc:	7179                	addi	sp,sp,-48
    800013be:	f406                	sd	ra,40(sp)
    800013c0:	f022                	sd	s0,32(sp)
    800013c2:	ec26                	sd	s1,24(sp)
    800013c4:	e84a                	sd	s2,16(sp)
    800013c6:	e44e                	sd	s3,8(sp)
    800013c8:	e052                	sd	s4,0(sp)
    800013ca:	1800                	addi	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    800013cc:	6785                	lui	a5,0x1
    800013ce:	04f67863          	bgeu	a2,a5,8000141e <uvmfirst+0x62>
    800013d2:	8a2a                	mv	s4,a0
    800013d4:	89ae                	mv	s3,a1
    800013d6:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013d8:	fffff097          	auipc	ra,0xfffff
    800013dc:	754080e7          	jalr	1876(ra) # 80000b2c <kalloc>
    800013e0:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013e2:	6605                	lui	a2,0x1
    800013e4:	4581                	li	a1,0
    800013e6:	00000097          	auipc	ra,0x0
    800013ea:	952080e7          	jalr	-1710(ra) # 80000d38 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    800013ee:	4779                	li	a4,30
    800013f0:	86ca                	mv	a3,s2
    800013f2:	6605                	lui	a2,0x1
    800013f4:	4581                	li	a1,0
    800013f6:	8552                	mv	a0,s4
    800013f8:	00000097          	auipc	ra,0x0
    800013fc:	d0c080e7          	jalr	-756(ra) # 80001104 <mappages>
  memmove(mem, src, sz);
    80001400:	8626                	mv	a2,s1
    80001402:	85ce                	mv	a1,s3
    80001404:	854a                	mv	a0,s2
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	98e080e7          	jalr	-1650(ra) # 80000d94 <memmove>
}
    8000140e:	70a2                	ld	ra,40(sp)
    80001410:	7402                	ld	s0,32(sp)
    80001412:	64e2                	ld	s1,24(sp)
    80001414:	6942                	ld	s2,16(sp)
    80001416:	69a2                	ld	s3,8(sp)
    80001418:	6a02                	ld	s4,0(sp)
    8000141a:	6145                	addi	sp,sp,48
    8000141c:	8082                	ret
    panic("uvmfirst: more than a page");
    8000141e:	00007517          	auipc	a0,0x7
    80001422:	d3a50513          	addi	a0,a0,-710 # 80008158 <digits+0x118>
    80001426:	fffff097          	auipc	ra,0xfffff
    8000142a:	118080e7          	jalr	280(ra) # 8000053e <panic>

000000008000142e <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000142e:	1101                	addi	sp,sp,-32
    80001430:	ec06                	sd	ra,24(sp)
    80001432:	e822                	sd	s0,16(sp)
    80001434:	e426                	sd	s1,8(sp)
    80001436:	1000                	addi	s0,sp,32
  if (newsz >= oldsz)
    return oldsz;
    80001438:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    8000143a:	00b67d63          	bgeu	a2,a1,80001454 <uvmdealloc+0x26>
    8000143e:	84b2                	mv	s1,a2

  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    80001440:	6785                	lui	a5,0x1
    80001442:	17fd                	addi	a5,a5,-1
    80001444:	00f60733          	add	a4,a2,a5
    80001448:	767d                	lui	a2,0xfffff
    8000144a:	8f71                	and	a4,a4,a2
    8000144c:	97ae                	add	a5,a5,a1
    8000144e:	8ff1                	and	a5,a5,a2
    80001450:	00f76863          	bltu	a4,a5,80001460 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001454:	8526                	mv	a0,s1
    80001456:	60e2                	ld	ra,24(sp)
    80001458:	6442                	ld	s0,16(sp)
    8000145a:	64a2                	ld	s1,8(sp)
    8000145c:	6105                	addi	sp,sp,32
    8000145e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001460:	8f99                	sub	a5,a5,a4
    80001462:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001464:	4685                	li	a3,1
    80001466:	0007861b          	sext.w	a2,a5
    8000146a:	85ba                	mv	a1,a4
    8000146c:	00000097          	auipc	ra,0x0
    80001470:	e5e080e7          	jalr	-418(ra) # 800012ca <uvmunmap>
    80001474:	b7c5                	j	80001454 <uvmdealloc+0x26>

0000000080001476 <uvmalloc>:
  if (newsz < oldsz)
    80001476:	0ab66563          	bltu	a2,a1,80001520 <uvmalloc+0xaa>
{
    8000147a:	7139                	addi	sp,sp,-64
    8000147c:	fc06                	sd	ra,56(sp)
    8000147e:	f822                	sd	s0,48(sp)
    80001480:	f426                	sd	s1,40(sp)
    80001482:	f04a                	sd	s2,32(sp)
    80001484:	ec4e                	sd	s3,24(sp)
    80001486:	e852                	sd	s4,16(sp)
    80001488:	e456                	sd	s5,8(sp)
    8000148a:	e05a                	sd	s6,0(sp)
    8000148c:	0080                	addi	s0,sp,64
    8000148e:	8aaa                	mv	s5,a0
    80001490:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001492:	6985                	lui	s3,0x1
    80001494:	19fd                	addi	s3,s3,-1
    80001496:	95ce                	add	a1,a1,s3
    80001498:	79fd                	lui	s3,0xfffff
    8000149a:	0135f9b3          	and	s3,a1,s3
  for (a = oldsz; a < newsz; a += PGSIZE)
    8000149e:	08c9f363          	bgeu	s3,a2,80001524 <uvmalloc+0xae>
    800014a2:	894e                	mv	s2,s3
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    800014a4:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800014a8:	fffff097          	auipc	ra,0xfffff
    800014ac:	684080e7          	jalr	1668(ra) # 80000b2c <kalloc>
    800014b0:	84aa                	mv	s1,a0
    if (mem == 0)
    800014b2:	c51d                	beqz	a0,800014e0 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800014b4:	6605                	lui	a2,0x1
    800014b6:	4581                	li	a1,0
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	880080e7          	jalr	-1920(ra) # 80000d38 <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    800014c0:	875a                	mv	a4,s6
    800014c2:	86a6                	mv	a3,s1
    800014c4:	6605                	lui	a2,0x1
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	c3a080e7          	jalr	-966(ra) # 80001104 <mappages>
    800014d2:	e90d                	bnez	a0,80001504 <uvmalloc+0x8e>
  for (a = oldsz; a < newsz; a += PGSIZE)
    800014d4:	6785                	lui	a5,0x1
    800014d6:	993e                	add	s2,s2,a5
    800014d8:	fd4968e3          	bltu	s2,s4,800014a8 <uvmalloc+0x32>
  return newsz;
    800014dc:	8552                	mv	a0,s4
    800014de:	a809                	j	800014f0 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014e0:	864e                	mv	a2,s3
    800014e2:	85ca                	mv	a1,s2
    800014e4:	8556                	mv	a0,s5
    800014e6:	00000097          	auipc	ra,0x0
    800014ea:	f48080e7          	jalr	-184(ra) # 8000142e <uvmdealloc>
      return 0;
    800014ee:	4501                	li	a0,0
}
    800014f0:	70e2                	ld	ra,56(sp)
    800014f2:	7442                	ld	s0,48(sp)
    800014f4:	74a2                	ld	s1,40(sp)
    800014f6:	7902                	ld	s2,32(sp)
    800014f8:	69e2                	ld	s3,24(sp)
    800014fa:	6a42                	ld	s4,16(sp)
    800014fc:	6aa2                	ld	s5,8(sp)
    800014fe:	6b02                	ld	s6,0(sp)
    80001500:	6121                	addi	sp,sp,64
    80001502:	8082                	ret
      kfree(mem);
    80001504:	8526                	mv	a0,s1
    80001506:	fffff097          	auipc	ra,0xfffff
    8000150a:	4e4080e7          	jalr	1252(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000150e:	864e                	mv	a2,s3
    80001510:	85ca                	mv	a1,s2
    80001512:	8556                	mv	a0,s5
    80001514:	00000097          	auipc	ra,0x0
    80001518:	f1a080e7          	jalr	-230(ra) # 8000142e <uvmdealloc>
      return 0;
    8000151c:	4501                	li	a0,0
    8000151e:	bfc9                	j	800014f0 <uvmalloc+0x7a>
    return oldsz;
    80001520:	852e                	mv	a0,a1
}
    80001522:	8082                	ret
  return newsz;
    80001524:	8532                	mv	a0,a2
    80001526:	b7e9                	j	800014f0 <uvmalloc+0x7a>

0000000080001528 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void freewalk(pagetable_t pagetable)
{
    80001528:	7179                	addi	sp,sp,-48
    8000152a:	f406                	sd	ra,40(sp)
    8000152c:	f022                	sd	s0,32(sp)
    8000152e:	ec26                	sd	s1,24(sp)
    80001530:	e84a                	sd	s2,16(sp)
    80001532:	e44e                	sd	s3,8(sp)
    80001534:	e052                	sd	s4,0(sp)
    80001536:	1800                	addi	s0,sp,48
    80001538:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for (int i = 0; i < 512; i++)
    8000153a:	84aa                	mv	s1,a0
    8000153c:	6905                	lui	s2,0x1
    8000153e:	992a                	add	s2,s2,a0
  {
    pte_t pte = pagetable[i];
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001540:	4985                	li	s3,1
    80001542:	a821                	j	8000155a <freewalk+0x32>
    {
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001544:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001546:	0532                	slli	a0,a0,0xc
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	fe0080e7          	jalr	-32(ra) # 80001528 <freewalk>
      pagetable[i] = 0;
    80001550:	0004b023          	sd	zero,0(s1)
  for (int i = 0; i < 512; i++)
    80001554:	04a1                	addi	s1,s1,8
    80001556:	03248163          	beq	s1,s2,80001578 <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000155a:	6088                	ld	a0,0(s1)
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    8000155c:	00f57793          	andi	a5,a0,15
    80001560:	ff3782e3          	beq	a5,s3,80001544 <freewalk+0x1c>
    }
    else if (pte & PTE_V)
    80001564:	8905                	andi	a0,a0,1
    80001566:	d57d                	beqz	a0,80001554 <freewalk+0x2c>
    {
      panic("freewalk: leaf");
    80001568:	00007517          	auipc	a0,0x7
    8000156c:	c1050513          	addi	a0,a0,-1008 # 80008178 <digits+0x138>
    80001570:	fffff097          	auipc	ra,0xfffff
    80001574:	fce080e7          	jalr	-50(ra) # 8000053e <panic>
    }
  }
  kfree((void *)pagetable);
    80001578:	8552                	mv	a0,s4
    8000157a:	fffff097          	auipc	ra,0xfffff
    8000157e:	470080e7          	jalr	1136(ra) # 800009ea <kfree>
}
    80001582:	70a2                	ld	ra,40(sp)
    80001584:	7402                	ld	s0,32(sp)
    80001586:	64e2                	ld	s1,24(sp)
    80001588:	6942                	ld	s2,16(sp)
    8000158a:	69a2                	ld	s3,8(sp)
    8000158c:	6a02                	ld	s4,0(sp)
    8000158e:	6145                	addi	sp,sp,48
    80001590:	8082                	ret

0000000080001592 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001592:	1101                	addi	sp,sp,-32
    80001594:	ec06                	sd	ra,24(sp)
    80001596:	e822                	sd	s0,16(sp)
    80001598:	e426                	sd	s1,8(sp)
    8000159a:	1000                	addi	s0,sp,32
    8000159c:	84aa                	mv	s1,a0
  if (sz > 0)
    8000159e:	e999                	bnez	a1,800015b4 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
  freewalk(pagetable);
    800015a0:	8526                	mv	a0,s1
    800015a2:	00000097          	auipc	ra,0x0
    800015a6:	f86080e7          	jalr	-122(ra) # 80001528 <freewalk>
}
    800015aa:	60e2                	ld	ra,24(sp)
    800015ac:	6442                	ld	s0,16(sp)
    800015ae:	64a2                	ld	s1,8(sp)
    800015b0:	6105                	addi	sp,sp,32
    800015b2:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
    800015b4:	6605                	lui	a2,0x1
    800015b6:	167d                	addi	a2,a2,-1
    800015b8:	962e                	add	a2,a2,a1
    800015ba:	4685                	li	a3,1
    800015bc:	8231                	srli	a2,a2,0xc
    800015be:	4581                	li	a1,0
    800015c0:	00000097          	auipc	ra,0x0
    800015c4:	d0a080e7          	jalr	-758(ra) # 800012ca <uvmunmap>
    800015c8:	bfe1                	j	800015a0 <uvmfree+0xe>

00000000800015ca <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags = 0;
  // char *mem;

  for (i = 0; i < sz; i += PGSIZE)
    800015ca:	ca75                	beqz	a2,800016be <uvmcopy+0xf4>
{
    800015cc:	715d                	addi	sp,sp,-80
    800015ce:	e486                	sd	ra,72(sp)
    800015d0:	e0a2                	sd	s0,64(sp)
    800015d2:	fc26                	sd	s1,56(sp)
    800015d4:	f84a                	sd	s2,48(sp)
    800015d6:	f44e                	sd	s3,40(sp)
    800015d8:	f052                	sd	s4,32(sp)
    800015da:	ec56                	sd	s5,24(sp)
    800015dc:	e85a                	sd	s6,16(sp)
    800015de:	e45e                	sd	s7,8(sp)
    800015e0:	e062                	sd	s8,0(sp)
    800015e2:	0880                	addi	s0,sp,80
    800015e4:	8baa                	mv	s7,a0
    800015e6:	8b2e                	mv	s6,a1
    800015e8:	8ab2                	mv	s5,a2
  for (i = 0; i < sz; i += PGSIZE)
    800015ea:	4981                	li	s3,0
      *pte |= (1L << 8);
    }
    pa = (((*pte) >> 10) << 12);

    // increment the ref count
    acquire(&reference_lock);
    800015ec:	0000fa17          	auipc	s4,0xf
    800015f0:	544a0a13          	addi	s4,s4,1348 # 80010b30 <reference_lock>
    reference_count[pa/PGSIZE] += 1;
    800015f4:	0000fc17          	auipc	s8,0xf
    800015f8:	574c0c13          	addi	s8,s8,1396 # 80010b68 <reference_count>
    800015fc:	a0b5                	j	80001668 <uvmcopy+0x9e>
      panic("uvmcopy: pte should exist");
    800015fe:	00007517          	auipc	a0,0x7
    80001602:	b8a50513          	addi	a0,a0,-1142 # 80008188 <digits+0x148>
    80001606:	fffff097          	auipc	ra,0xfffff
    8000160a:	f38080e7          	jalr	-200(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    8000160e:	00007517          	auipc	a0,0x7
    80001612:	b9a50513          	addi	a0,a0,-1126 # 800081a8 <digits+0x168>
    80001616:	fffff097          	auipc	ra,0xfffff
    8000161a:	f28080e7          	jalr	-216(ra) # 8000053e <panic>
    pa = (((*pte) >> 10) << 12);
    8000161e:	0004b903          	ld	s2,0(s1)
    80001622:	00a95913          	srli	s2,s2,0xa
    80001626:	0932                	slli	s2,s2,0xc
    acquire(&reference_lock);
    80001628:	8552                	mv	a0,s4
    8000162a:	fffff097          	auipc	ra,0xfffff
    8000162e:	612080e7          	jalr	1554(ra) # 80000c3c <acquire>
    reference_count[pa/PGSIZE] += 1;
    80001632:	00a95793          	srli	a5,s2,0xa
    80001636:	97e2                	add	a5,a5,s8
    80001638:	4398                	lw	a4,0(a5)
    8000163a:	2705                	addiw	a4,a4,1
    8000163c:	c398                	sw	a4,0(a5)
    release(&reference_lock);
    8000163e:	8552                	mv	a0,s4
    80001640:	fffff097          	auipc	ra,0xfffff
    80001644:	6b0080e7          	jalr	1712(ra) # 80000cf0 <release>

    flags = ((*pte) & 0x3FF);
    80001648:	6098                	ld	a4,0(s1)
    // flags = ((*pte) & 0x3FF);
    if (mappages(new, i, 4096, (uint64)pa, flags) != 0)
    8000164a:	3ff77713          	andi	a4,a4,1023
    8000164e:	86ca                	mv	a3,s2
    80001650:	6605                	lui	a2,0x1
    80001652:	85ce                	mv	a1,s3
    80001654:	855a                	mv	a0,s6
    80001656:	00000097          	auipc	ra,0x0
    8000165a:	aae080e7          	jalr	-1362(ra) # 80001104 <mappages>
    8000165e:	e915                	bnez	a0,80001692 <uvmcopy+0xc8>
  for (i = 0; i < sz; i += PGSIZE)
    80001660:	6785                	lui	a5,0x1
    80001662:	99be                	add	s3,s3,a5
    80001664:	0559f163          	bgeu	s3,s5,800016a6 <uvmcopy+0xdc>
    if ((pte = walk(old, i, 0)) == 0)
    80001668:	4601                	li	a2,0
    8000166a:	85ce                	mv	a1,s3
    8000166c:	855e                	mv	a0,s7
    8000166e:	00000097          	auipc	ra,0x0
    80001672:	9ae080e7          	jalr	-1618(ra) # 8000101c <walk>
    80001676:	84aa                	mv	s1,a0
    80001678:	d159                	beqz	a0,800015fe <uvmcopy+0x34>
    if ((*pte & PTE_V) == 0)
    8000167a:	611c                	ld	a5,0(a0)
    8000167c:	0017f713          	andi	a4,a5,1
    80001680:	d759                	beqz	a4,8000160e <uvmcopy+0x44>
    if (*pte & PTE_W)
    80001682:	0047f713          	andi	a4,a5,4
    80001686:	df41                	beqz	a4,8000161e <uvmcopy+0x54>
      *pte &= ~(1L << 2);
    80001688:	9bed                	andi	a5,a5,-5
      *pte |= (1L << 8);
    8000168a:	1007e793          	ori	a5,a5,256
    8000168e:	e11c                	sd	a5,0(a0)
    80001690:	b779                	j	8000161e <uvmcopy+0x54>
    // }
  }
  return 0;

err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001692:	4685                	li	a3,1
    80001694:	00c9d613          	srli	a2,s3,0xc
    80001698:	4581                	li	a1,0
    8000169a:	855a                	mv	a0,s6
    8000169c:	00000097          	auipc	ra,0x0
    800016a0:	c2e080e7          	jalr	-978(ra) # 800012ca <uvmunmap>
  return -1;
    800016a4:	557d                	li	a0,-1
}
    800016a6:	60a6                	ld	ra,72(sp)
    800016a8:	6406                	ld	s0,64(sp)
    800016aa:	74e2                	ld	s1,56(sp)
    800016ac:	7942                	ld	s2,48(sp)
    800016ae:	79a2                	ld	s3,40(sp)
    800016b0:	7a02                	ld	s4,32(sp)
    800016b2:	6ae2                	ld	s5,24(sp)
    800016b4:	6b42                	ld	s6,16(sp)
    800016b6:	6ba2                	ld	s7,8(sp)
    800016b8:	6c02                	ld	s8,0(sp)
    800016ba:	6161                	addi	sp,sp,80
    800016bc:	8082                	ret
  return 0;
    800016be:	4501                	li	a0,0
}
    800016c0:	8082                	ret

00000000800016c2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void uvmclear(pagetable_t pagetable, uint64 va)
{
    800016c2:	1141                	addi	sp,sp,-16
    800016c4:	e406                	sd	ra,8(sp)
    800016c6:	e022                	sd	s0,0(sp)
    800016c8:	0800                	addi	s0,sp,16
  pte_t *pte;

  pte = walk(pagetable, va, 0);
    800016ca:	4601                	li	a2,0
    800016cc:	00000097          	auipc	ra,0x0
    800016d0:	950080e7          	jalr	-1712(ra) # 8000101c <walk>
  if (pte == 0)
    800016d4:	c901                	beqz	a0,800016e4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016d6:	611c                	ld	a5,0(a0)
    800016d8:	9bbd                	andi	a5,a5,-17
    800016da:	e11c                	sd	a5,0(a0)
}
    800016dc:	60a2                	ld	ra,8(sp)
    800016de:	6402                	ld	s0,0(sp)
    800016e0:	0141                	addi	sp,sp,16
    800016e2:	8082                	ret
    panic("uvmclear");
    800016e4:	00007517          	auipc	a0,0x7
    800016e8:	ae450513          	addi	a0,a0,-1308 # 800081c8 <digits+0x188>
    800016ec:	fffff097          	auipc	ra,0xfffff
    800016f0:	e52080e7          	jalr	-430(ra) # 8000053e <panic>

00000000800016f4 <copyout>:

int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, virt_addr, ph_addr_0;

  while (len > 0)
    800016f4:	cef5                	beqz	a3,800017f0 <copyout+0xfc>
{
    800016f6:	7159                	addi	sp,sp,-112
    800016f8:	f486                	sd	ra,104(sp)
    800016fa:	f0a2                	sd	s0,96(sp)
    800016fc:	eca6                	sd	s1,88(sp)
    800016fe:	e8ca                	sd	s2,80(sp)
    80001700:	e4ce                	sd	s3,72(sp)
    80001702:	e0d2                	sd	s4,64(sp)
    80001704:	fc56                	sd	s5,56(sp)
    80001706:	f85a                	sd	s6,48(sp)
    80001708:	f45e                	sd	s7,40(sp)
    8000170a:	f062                	sd	s8,32(sp)
    8000170c:	ec66                	sd	s9,24(sp)
    8000170e:	e86a                	sd	s10,16(sp)
    80001710:	e46e                	sd	s11,8(sp)
    80001712:	1880                	addi	s0,sp,112
    80001714:	8c2a                	mv	s8,a0
    80001716:	84ae                	mv	s1,a1
    80001718:	8bb2                	mv	s7,a2
    8000171a:	8a36                	mv	s4,a3
  {
    virt_addr = (((dstva)) & ~(4096 - 1));
    8000171c:	7cfd                	lui	s9,0xfffff
    // if(cowtest_h(pagetable,virt_addr)<0)
    // return -1;
    struct proc *p = myproc();
    pte_t *pte = walk(pagetable, virt_addr, 0);
    if (*pte == 0)
      p->killed = 1;
    8000171e:	4d05                	li	s10,1
    if ((virt_addr < p->sz) && (*pte & PTE_V) && (*pte & PTE_RSW))
    80001720:	10100d93          	li	s11,257
    80001724:	a81d                	j	8000175a <copyout+0x66>
      char *mem;
      // p->killed = 1;
      if ((mem = kalloc()) == 0)
      {
        // kill prcess
        p->killed = 1;
    80001726:	03ab2423          	sw	s10,40(s6) # 1028 <_entry-0x7fffefd8>
        *pte = (((((uint64)mem) >> 12) << 10) | flags | (1L << 2)); // change the physical memory address and set PTE_W to 1
        *pte &= ~(1L << 8);                                         // set PTE_RSW to 0
        ph_addr_0 = (uint64)mem;                                    // update pa0 to new physical memory address
      }
    }
    n = 4096 - (dstva - virt_addr);
    8000172a:	40990ab3          	sub	s5,s2,s1
    8000172e:	6785                	lui	a5,0x1
    80001730:	9abe                	add	s5,s5,a5
    if (n > len)
    80001732:	015a7363          	bgeu	s4,s5,80001738 <copyout+0x44>
    80001736:	8ad2                	mv	s5,s4
      n = len;
    memmove((void *)(ph_addr_0 + (dstva - virt_addr)), src, n);
    80001738:	41248533          	sub	a0,s1,s2
    8000173c:	000a861b          	sext.w	a2,s5
    80001740:	85de                	mv	a1,s7
    80001742:	954e                	add	a0,a0,s3
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	650080e7          	jalr	1616(ra) # 80000d94 <memmove>

    len -= n;
    8000174c:	415a0a33          	sub	s4,s4,s5
    src += n;
    80001750:	9bd6                	add	s7,s7,s5
    dstva = virt_addr + 4096;
    80001752:	6485                	lui	s1,0x1
    80001754:	94ca                	add	s1,s1,s2
  while (len > 0)
    80001756:	080a0b63          	beqz	s4,800017ec <copyout+0xf8>
    virt_addr = (((dstva)) & ~(4096 - 1));
    8000175a:	0194f933          	and	s2,s1,s9
    ph_addr_0 = walkaddr(pagetable, virt_addr);
    8000175e:	85ca                	mv	a1,s2
    80001760:	8562                	mv	a0,s8
    80001762:	00000097          	auipc	ra,0x0
    80001766:	960080e7          	jalr	-1696(ra) # 800010c2 <walkaddr>
    8000176a:	89aa                	mv	s3,a0
    if (ph_addr_0 == 0)
    8000176c:	c541                	beqz	a0,800017f4 <copyout+0x100>
    struct proc *p = myproc();
    8000176e:	00000097          	auipc	ra,0x0
    80001772:	35e080e7          	jalr	862(ra) # 80001acc <myproc>
    80001776:	8b2a                	mv	s6,a0
    pte_t *pte = walk(pagetable, virt_addr, 0);
    80001778:	4601                	li	a2,0
    8000177a:	85ca                	mv	a1,s2
    8000177c:	8562                	mv	a0,s8
    8000177e:	00000097          	auipc	ra,0x0
    80001782:	89e080e7          	jalr	-1890(ra) # 8000101c <walk>
    80001786:	8aaa                	mv	s5,a0
    if (*pte == 0)
    80001788:	611c                	ld	a5,0(a0)
    8000178a:	e399                	bnez	a5,80001790 <copyout+0x9c>
      p->killed = 1;
    8000178c:	03ab2423          	sw	s10,40(s6)
    if ((virt_addr < p->sz) && (*pte & PTE_V) && (*pte & PTE_RSW))
    80001790:	048b3783          	ld	a5,72(s6)
    80001794:	f8f97be3          	bgeu	s2,a5,8000172a <copyout+0x36>
    80001798:	000ab783          	ld	a5,0(s5)
    8000179c:	1017f793          	andi	a5,a5,257
    800017a0:	f9b795e3          	bne	a5,s11,8000172a <copyout+0x36>
      if ((mem = kalloc()) == 0)
    800017a4:	fffff097          	auipc	ra,0xfffff
    800017a8:	388080e7          	jalr	904(ra) # 80000b2c <kalloc>
    800017ac:	dd2d                	beqz	a0,80001726 <copyout+0x32>
        memmove(mem, (char *)ph_addr_0, 4096);
    800017ae:	6605                	lui	a2,0x1
    800017b0:	85ce                	mv	a1,s3
    800017b2:	89aa                	mv	s3,a0
    800017b4:	fffff097          	auipc	ra,0xfffff
    800017b8:	5e0080e7          	jalr	1504(ra) # 80000d94 <memmove>
        uint flags = ((*pte) & 0x3FF);
    800017bc:	000abb03          	ld	s6,0(s5)
    800017c0:	3ffb7b13          	andi	s6,s6,1023
        uvmunmap(pagetable, virt_addr, 1, 1);
    800017c4:	86ea                	mv	a3,s10
    800017c6:	866a                	mv	a2,s10
    800017c8:	85ca                	mv	a1,s2
    800017ca:	8562                	mv	a0,s8
    800017cc:	00000097          	auipc	ra,0x0
    800017d0:	afe080e7          	jalr	-1282(ra) # 800012ca <uvmunmap>
        *pte = (((((uint64)mem) >> 12) << 10) | flags | (1L << 2)); // change the physical memory address and set PTE_W to 1
    800017d4:	00c9d793          	srli	a5,s3,0xc
    800017d8:	07aa                	slli	a5,a5,0xa
    800017da:	00fb67b3          	or	a5,s6,a5
        *pte &= ~(1L << 8);                                         // set PTE_RSW to 0
    800017de:	eff7f793          	andi	a5,a5,-257
    800017e2:	0047e793          	ori	a5,a5,4
    800017e6:	00fab023          	sd	a5,0(s5)
        ph_addr_0 = (uint64)mem;                                    // update pa0 to new physical memory address
    800017ea:	b781                	j	8000172a <copyout+0x36>
  }
  return 0;
    800017ec:	4501                	li	a0,0
    800017ee:	a021                	j	800017f6 <copyout+0x102>
    800017f0:	4501                	li	a0,0
}
    800017f2:	8082                	ret
      return -1;
    800017f4:	557d                	li	a0,-1
}
    800017f6:	70a6                	ld	ra,104(sp)
    800017f8:	7406                	ld	s0,96(sp)
    800017fa:	64e6                	ld	s1,88(sp)
    800017fc:	6946                	ld	s2,80(sp)
    800017fe:	69a6                	ld	s3,72(sp)
    80001800:	6a06                	ld	s4,64(sp)
    80001802:	7ae2                	ld	s5,56(sp)
    80001804:	7b42                	ld	s6,48(sp)
    80001806:	7ba2                	ld	s7,40(sp)
    80001808:	7c02                	ld	s8,32(sp)
    8000180a:	6ce2                	ld	s9,24(sp)
    8000180c:	6d42                	ld	s10,16(sp)
    8000180e:	6da2                	ld	s11,8(sp)
    80001810:	6165                	addi	sp,sp,112
    80001812:	8082                	ret

0000000080001814 <copyin>:
// Return 0 on success, -1 on error.
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    80001814:	caa5                	beqz	a3,80001884 <copyin+0x70>
{
    80001816:	715d                	addi	sp,sp,-80
    80001818:	e486                	sd	ra,72(sp)
    8000181a:	e0a2                	sd	s0,64(sp)
    8000181c:	fc26                	sd	s1,56(sp)
    8000181e:	f84a                	sd	s2,48(sp)
    80001820:	f44e                	sd	s3,40(sp)
    80001822:	f052                	sd	s4,32(sp)
    80001824:	ec56                	sd	s5,24(sp)
    80001826:	e85a                	sd	s6,16(sp)
    80001828:	e45e                	sd	s7,8(sp)
    8000182a:	e062                	sd	s8,0(sp)
    8000182c:	0880                	addi	s0,sp,80
    8000182e:	8b2a                	mv	s6,a0
    80001830:	8a2e                	mv	s4,a1
    80001832:	8c32                	mv	s8,a2
    80001834:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(srcva);
    80001836:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001838:	6a85                	lui	s5,0x1
    8000183a:	a01d                	j	80001860 <copyin+0x4c>
    if (n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000183c:	018505b3          	add	a1,a0,s8
    80001840:	0004861b          	sext.w	a2,s1
    80001844:	412585b3          	sub	a1,a1,s2
    80001848:	8552                	mv	a0,s4
    8000184a:	fffff097          	auipc	ra,0xfffff
    8000184e:	54a080e7          	jalr	1354(ra) # 80000d94 <memmove>

    len -= n;
    80001852:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001856:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001858:	01590c33          	add	s8,s2,s5
  while (len > 0)
    8000185c:	02098263          	beqz	s3,80001880 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001860:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001864:	85ca                	mv	a1,s2
    80001866:	855a                	mv	a0,s6
    80001868:	00000097          	auipc	ra,0x0
    8000186c:	85a080e7          	jalr	-1958(ra) # 800010c2 <walkaddr>
    if (pa0 == 0)
    80001870:	cd01                	beqz	a0,80001888 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001872:	418904b3          	sub	s1,s2,s8
    80001876:	94d6                	add	s1,s1,s5
    if (n > len)
    80001878:	fc99f2e3          	bgeu	s3,s1,8000183c <copyin+0x28>
    8000187c:	84ce                	mv	s1,s3
    8000187e:	bf7d                	j	8000183c <copyin+0x28>
  }
  return 0;
    80001880:	4501                	li	a0,0
    80001882:	a021                	j	8000188a <copyin+0x76>
    80001884:	4501                	li	a0,0
}
    80001886:	8082                	ret
      return -1;
    80001888:	557d                	li	a0,-1
}
    8000188a:	60a6                	ld	ra,72(sp)
    8000188c:	6406                	ld	s0,64(sp)
    8000188e:	74e2                	ld	s1,56(sp)
    80001890:	7942                	ld	s2,48(sp)
    80001892:	79a2                	ld	s3,40(sp)
    80001894:	7a02                	ld	s4,32(sp)
    80001896:	6ae2                	ld	s5,24(sp)
    80001898:	6b42                	ld	s6,16(sp)
    8000189a:	6ba2                	ld	s7,8(sp)
    8000189c:	6c02                	ld	s8,0(sp)
    8000189e:	6161                	addi	sp,sp,80
    800018a0:	8082                	ret

00000000800018a2 <copyinstr>:
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && max > 0)
    800018a2:	c6c5                	beqz	a3,8000194a <copyinstr+0xa8>
{
    800018a4:	715d                	addi	sp,sp,-80
    800018a6:	e486                	sd	ra,72(sp)
    800018a8:	e0a2                	sd	s0,64(sp)
    800018aa:	fc26                	sd	s1,56(sp)
    800018ac:	f84a                	sd	s2,48(sp)
    800018ae:	f44e                	sd	s3,40(sp)
    800018b0:	f052                	sd	s4,32(sp)
    800018b2:	ec56                	sd	s5,24(sp)
    800018b4:	e85a                	sd	s6,16(sp)
    800018b6:	e45e                	sd	s7,8(sp)
    800018b8:	0880                	addi	s0,sp,80
    800018ba:	8a2a                	mv	s4,a0
    800018bc:	8b2e                	mv	s6,a1
    800018be:	8bb2                	mv	s7,a2
    800018c0:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    800018c2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018c4:	6985                	lui	s3,0x1
    800018c6:	a035                	j	800018f2 <copyinstr+0x50>
    char *p = (char *)(pa0 + (srcva - va0));
    while (n > 0)
    {
      if (*p == '\0')
      {
        *dst = '\0';
    800018c8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018cc:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if (got_null)
    800018ce:	0017b793          	seqz	a5,a5
    800018d2:	40f00533          	neg	a0,a5
  }
  else
  {
    return -1;
  }
}
    800018d6:	60a6                	ld	ra,72(sp)
    800018d8:	6406                	ld	s0,64(sp)
    800018da:	74e2                	ld	s1,56(sp)
    800018dc:	7942                	ld	s2,48(sp)
    800018de:	79a2                	ld	s3,40(sp)
    800018e0:	7a02                	ld	s4,32(sp)
    800018e2:	6ae2                	ld	s5,24(sp)
    800018e4:	6b42                	ld	s6,16(sp)
    800018e6:	6ba2                	ld	s7,8(sp)
    800018e8:	6161                	addi	sp,sp,80
    800018ea:	8082                	ret
    srcva = va0 + PGSIZE;
    800018ec:	01390bb3          	add	s7,s2,s3
  while (got_null == 0 && max > 0)
    800018f0:	c8a9                	beqz	s1,80001942 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018f2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018f6:	85ca                	mv	a1,s2
    800018f8:	8552                	mv	a0,s4
    800018fa:	fffff097          	auipc	ra,0xfffff
    800018fe:	7c8080e7          	jalr	1992(ra) # 800010c2 <walkaddr>
    if (pa0 == 0)
    80001902:	c131                	beqz	a0,80001946 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001904:	41790833          	sub	a6,s2,s7
    80001908:	984e                	add	a6,a6,s3
    if (n > max)
    8000190a:	0104f363          	bgeu	s1,a6,80001910 <copyinstr+0x6e>
    8000190e:	8826                	mv	a6,s1
    char *p = (char *)(pa0 + (srcva - va0));
    80001910:	955e                	add	a0,a0,s7
    80001912:	41250533          	sub	a0,a0,s2
    while (n > 0)
    80001916:	fc080be3          	beqz	a6,800018ec <copyinstr+0x4a>
    8000191a:	985a                	add	a6,a6,s6
    8000191c:	87da                	mv	a5,s6
      if (*p == '\0')
    8000191e:	41650633          	sub	a2,a0,s6
    80001922:	14fd                	addi	s1,s1,-1
    80001924:	9b26                	add	s6,s6,s1
    80001926:	00f60733          	add	a4,a2,a5
    8000192a:	00074703          	lbu	a4,0(a4)
    8000192e:	df49                	beqz	a4,800018c8 <copyinstr+0x26>
        *dst = *p;
    80001930:	00e78023          	sb	a4,0(a5)
      --max;
    80001934:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001938:	0785                	addi	a5,a5,1
    while (n > 0)
    8000193a:	ff0796e3          	bne	a5,a6,80001926 <copyinstr+0x84>
      dst++;
    8000193e:	8b42                	mv	s6,a6
    80001940:	b775                	j	800018ec <copyinstr+0x4a>
    80001942:	4781                	li	a5,0
    80001944:	b769                	j	800018ce <copyinstr+0x2c>
      return -1;
    80001946:	557d                	li	a0,-1
    80001948:	b779                	j	800018d6 <copyinstr+0x34>
  int got_null = 0;
    8000194a:	4781                	li	a5,0
  if (got_null)
    8000194c:	0017b793          	seqz	a5,a5
    80001950:	40f00533          	neg	a0,a5
}
    80001954:	8082                	ret

0000000080001956 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001956:	7139                	addi	sp,sp,-64
    80001958:	fc06                	sd	ra,56(sp)
    8000195a:	f822                	sd	s0,48(sp)
    8000195c:	f426                	sd	s1,40(sp)
    8000195e:	f04a                	sd	s2,32(sp)
    80001960:	ec4e                	sd	s3,24(sp)
    80001962:	e852                	sd	s4,16(sp)
    80001964:	e456                	sd	s5,8(sp)
    80001966:	e05a                	sd	s6,0(sp)
    80001968:	0080                	addi	s0,sp,64
    8000196a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000196c:	0022f497          	auipc	s1,0x22f
    80001970:	62c48493          	addi	s1,s1,1580 # 80230f98 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001974:	8b26                	mv	s6,s1
    80001976:	00006a97          	auipc	s5,0x6
    8000197a:	68aa8a93          	addi	s5,s5,1674 # 80008000 <etext>
    8000197e:	04000937          	lui	s2,0x4000
    80001982:	197d                	addi	s2,s2,-1
    80001984:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001986:	00236a17          	auipc	s4,0x236
    8000198a:	c12a0a13          	addi	s4,s4,-1006 # 80237598 <tickslock>
    char *pa = kalloc();
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	19e080e7          	jalr	414(ra) # 80000b2c <kalloc>
    80001996:	862a                	mv	a2,a0
    if (pa == 0)
    80001998:	c131                	beqz	a0,800019dc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000199a:	416485b3          	sub	a1,s1,s6
    8000199e:	858d                	srai	a1,a1,0x3
    800019a0:	000ab783          	ld	a5,0(s5)
    800019a4:	02f585b3          	mul	a1,a1,a5
    800019a8:	2585                	addiw	a1,a1,1
    800019aa:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019ae:	4719                	li	a4,6
    800019b0:	6685                	lui	a3,0x1
    800019b2:	40b905b3          	sub	a1,s2,a1
    800019b6:	854e                	mv	a0,s3
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	7ec080e7          	jalr	2028(ra) # 800011a4 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800019c0:	19848493          	addi	s1,s1,408
    800019c4:	fd4495e3          	bne	s1,s4,8000198e <proc_mapstacks+0x38>
  }
}
    800019c8:	70e2                	ld	ra,56(sp)
    800019ca:	7442                	ld	s0,48(sp)
    800019cc:	74a2                	ld	s1,40(sp)
    800019ce:	7902                	ld	s2,32(sp)
    800019d0:	69e2                	ld	s3,24(sp)
    800019d2:	6a42                	ld	s4,16(sp)
    800019d4:	6aa2                	ld	s5,8(sp)
    800019d6:	6b02                	ld	s6,0(sp)
    800019d8:	6121                	addi	sp,sp,64
    800019da:	8082                	ret
      panic("kalloc");
    800019dc:	00006517          	auipc	a0,0x6
    800019e0:	7fc50513          	addi	a0,a0,2044 # 800081d8 <digits+0x198>
    800019e4:	fffff097          	auipc	ra,0xfffff
    800019e8:	b5a080e7          	jalr	-1190(ra) # 8000053e <panic>

00000000800019ec <procinit>:

// initialize the proc table.
void procinit(void)
{
    800019ec:	7139                	addi	sp,sp,-64
    800019ee:	fc06                	sd	ra,56(sp)
    800019f0:	f822                	sd	s0,48(sp)
    800019f2:	f426                	sd	s1,40(sp)
    800019f4:	f04a                	sd	s2,32(sp)
    800019f6:	ec4e                	sd	s3,24(sp)
    800019f8:	e852                	sd	s4,16(sp)
    800019fa:	e456                	sd	s5,8(sp)
    800019fc:	e05a                	sd	s6,0(sp)
    800019fe:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001a00:	00006597          	auipc	a1,0x6
    80001a04:	7e058593          	addi	a1,a1,2016 # 800081e0 <digits+0x1a0>
    80001a08:	0022f517          	auipc	a0,0x22f
    80001a0c:	16050513          	addi	a0,a0,352 # 80230b68 <pid_lock>
    80001a10:	fffff097          	auipc	ra,0xfffff
    80001a14:	19c080e7          	jalr	412(ra) # 80000bac <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a18:	00006597          	auipc	a1,0x6
    80001a1c:	7d058593          	addi	a1,a1,2000 # 800081e8 <digits+0x1a8>
    80001a20:	0022f517          	auipc	a0,0x22f
    80001a24:	16050513          	addi	a0,a0,352 # 80230b80 <wait_lock>
    80001a28:	fffff097          	auipc	ra,0xfffff
    80001a2c:	184080e7          	jalr	388(ra) # 80000bac <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a30:	0022f497          	auipc	s1,0x22f
    80001a34:	56848493          	addi	s1,s1,1384 # 80230f98 <proc>
  {
    initlock(&p->lock, "proc");
    80001a38:	00006b17          	auipc	s6,0x6
    80001a3c:	7c0b0b13          	addi	s6,s6,1984 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001a40:	8aa6                	mv	s5,s1
    80001a42:	00006a17          	auipc	s4,0x6
    80001a46:	5bea0a13          	addi	s4,s4,1470 # 80008000 <etext>
    80001a4a:	04000937          	lui	s2,0x4000
    80001a4e:	197d                	addi	s2,s2,-1
    80001a50:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a52:	00236997          	auipc	s3,0x236
    80001a56:	b4698993          	addi	s3,s3,-1210 # 80237598 <tickslock>
    initlock(&p->lock, "proc");
    80001a5a:	85da                	mv	a1,s6
    80001a5c:	8526                	mv	a0,s1
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	14e080e7          	jalr	334(ra) # 80000bac <initlock>
    p->state = UNUSED;
    80001a66:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001a6a:	415487b3          	sub	a5,s1,s5
    80001a6e:	878d                	srai	a5,a5,0x3
    80001a70:	000a3703          	ld	a4,0(s4)
    80001a74:	02e787b3          	mul	a5,a5,a4
    80001a78:	2785                	addiw	a5,a5,1
    80001a7a:	00d7979b          	slliw	a5,a5,0xd
    80001a7e:	40f907b3          	sub	a5,s2,a5
    80001a82:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a84:	19848493          	addi	s1,s1,408
    80001a88:	fd3499e3          	bne	s1,s3,80001a5a <procinit+0x6e>
  }
}
    80001a8c:	70e2                	ld	ra,56(sp)
    80001a8e:	7442                	ld	s0,48(sp)
    80001a90:	74a2                	ld	s1,40(sp)
    80001a92:	7902                	ld	s2,32(sp)
    80001a94:	69e2                	ld	s3,24(sp)
    80001a96:	6a42                	ld	s4,16(sp)
    80001a98:	6aa2                	ld	s5,8(sp)
    80001a9a:	6b02                	ld	s6,0(sp)
    80001a9c:	6121                	addi	sp,sp,64
    80001a9e:	8082                	ret

0000000080001aa0 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001aa0:	1141                	addi	sp,sp,-16
    80001aa2:	e422                	sd	s0,8(sp)
    80001aa4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001aa6:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001aa8:	2501                	sext.w	a0,a0
    80001aaa:	6422                	ld	s0,8(sp)
    80001aac:	0141                	addi	sp,sp,16
    80001aae:	8082                	ret

0000000080001ab0 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001ab0:	1141                	addi	sp,sp,-16
    80001ab2:	e422                	sd	s0,8(sp)
    80001ab4:	0800                	addi	s0,sp,16
    80001ab6:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ab8:	2781                	sext.w	a5,a5
    80001aba:	079e                	slli	a5,a5,0x7
  return c;
}
    80001abc:	0022f517          	auipc	a0,0x22f
    80001ac0:	0dc50513          	addi	a0,a0,220 # 80230b98 <cpus>
    80001ac4:	953e                	add	a0,a0,a5
    80001ac6:	6422                	ld	s0,8(sp)
    80001ac8:	0141                	addi	sp,sp,16
    80001aca:	8082                	ret

0000000080001acc <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001acc:	1101                	addi	sp,sp,-32
    80001ace:	ec06                	sd	ra,24(sp)
    80001ad0:	e822                	sd	s0,16(sp)
    80001ad2:	e426                	sd	s1,8(sp)
    80001ad4:	1000                	addi	s0,sp,32
  push_off();
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	11a080e7          	jalr	282(ra) # 80000bf0 <push_off>
    80001ade:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ae0:	2781                	sext.w	a5,a5
    80001ae2:	079e                	slli	a5,a5,0x7
    80001ae4:	0022f717          	auipc	a4,0x22f
    80001ae8:	08470713          	addi	a4,a4,132 # 80230b68 <pid_lock>
    80001aec:	97ba                	add	a5,a5,a4
    80001aee:	7b84                	ld	s1,48(a5)
  pop_off();
    80001af0:	fffff097          	auipc	ra,0xfffff
    80001af4:	1a0080e7          	jalr	416(ra) # 80000c90 <pop_off>
  return p;
}
    80001af8:	8526                	mv	a0,s1
    80001afa:	60e2                	ld	ra,24(sp)
    80001afc:	6442                	ld	s0,16(sp)
    80001afe:	64a2                	ld	s1,8(sp)
    80001b00:	6105                	addi	sp,sp,32
    80001b02:	8082                	ret

0000000080001b04 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001b04:	1141                	addi	sp,sp,-16
    80001b06:	e406                	sd	ra,8(sp)
    80001b08:	e022                	sd	s0,0(sp)
    80001b0a:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b0c:	00000097          	auipc	ra,0x0
    80001b10:	fc0080e7          	jalr	-64(ra) # 80001acc <myproc>
    80001b14:	fffff097          	auipc	ra,0xfffff
    80001b18:	1dc080e7          	jalr	476(ra) # 80000cf0 <release>

  if (first)
    80001b1c:	00007797          	auipc	a5,0x7
    80001b20:	d447a783          	lw	a5,-700(a5) # 80008860 <first.1>
    80001b24:	eb89                	bnez	a5,80001b36 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b26:	00001097          	auipc	ra,0x1
    80001b2a:	256080e7          	jalr	598(ra) # 80002d7c <usertrapret>
}
    80001b2e:	60a2                	ld	ra,8(sp)
    80001b30:	6402                	ld	s0,0(sp)
    80001b32:	0141                	addi	sp,sp,16
    80001b34:	8082                	ret
    first = 0;
    80001b36:	00007797          	auipc	a5,0x7
    80001b3a:	d207a523          	sw	zero,-726(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001b3e:	4505                	li	a0,1
    80001b40:	00002097          	auipc	ra,0x2
    80001b44:	07a080e7          	jalr	122(ra) # 80003bba <fsinit>
    80001b48:	bff9                	j	80001b26 <forkret+0x22>

0000000080001b4a <allocpid>:
{
    80001b4a:	1101                	addi	sp,sp,-32
    80001b4c:	ec06                	sd	ra,24(sp)
    80001b4e:	e822                	sd	s0,16(sp)
    80001b50:	e426                	sd	s1,8(sp)
    80001b52:	e04a                	sd	s2,0(sp)
    80001b54:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b56:	0022f917          	auipc	s2,0x22f
    80001b5a:	01290913          	addi	s2,s2,18 # 80230b68 <pid_lock>
    80001b5e:	854a                	mv	a0,s2
    80001b60:	fffff097          	auipc	ra,0xfffff
    80001b64:	0dc080e7          	jalr	220(ra) # 80000c3c <acquire>
  pid = nextpid;
    80001b68:	00007797          	auipc	a5,0x7
    80001b6c:	cfc78793          	addi	a5,a5,-772 # 80008864 <nextpid>
    80001b70:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b72:	0014871b          	addiw	a4,s1,1
    80001b76:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b78:	854a                	mv	a0,s2
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	176080e7          	jalr	374(ra) # 80000cf0 <release>
}
    80001b82:	8526                	mv	a0,s1
    80001b84:	60e2                	ld	ra,24(sp)
    80001b86:	6442                	ld	s0,16(sp)
    80001b88:	64a2                	ld	s1,8(sp)
    80001b8a:	6902                	ld	s2,0(sp)
    80001b8c:	6105                	addi	sp,sp,32
    80001b8e:	8082                	ret

0000000080001b90 <proc_pagetable>:
{
    80001b90:	1101                	addi	sp,sp,-32
    80001b92:	ec06                	sd	ra,24(sp)
    80001b94:	e822                	sd	s0,16(sp)
    80001b96:	e426                	sd	s1,8(sp)
    80001b98:	e04a                	sd	s2,0(sp)
    80001b9a:	1000                	addi	s0,sp,32
    80001b9c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b9e:	fffff097          	auipc	ra,0xfffff
    80001ba2:	7f0080e7          	jalr	2032(ra) # 8000138e <uvmcreate>
    80001ba6:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001ba8:	c121                	beqz	a0,80001be8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001baa:	4729                	li	a4,10
    80001bac:	00005697          	auipc	a3,0x5
    80001bb0:	45468693          	addi	a3,a3,1108 # 80007000 <_trampoline>
    80001bb4:	6605                	lui	a2,0x1
    80001bb6:	040005b7          	lui	a1,0x4000
    80001bba:	15fd                	addi	a1,a1,-1
    80001bbc:	05b2                	slli	a1,a1,0xc
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	546080e7          	jalr	1350(ra) # 80001104 <mappages>
    80001bc6:	02054863          	bltz	a0,80001bf6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bca:	4719                	li	a4,6
    80001bcc:	05893683          	ld	a3,88(s2)
    80001bd0:	6605                	lui	a2,0x1
    80001bd2:	020005b7          	lui	a1,0x2000
    80001bd6:	15fd                	addi	a1,a1,-1
    80001bd8:	05b6                	slli	a1,a1,0xd
    80001bda:	8526                	mv	a0,s1
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	528080e7          	jalr	1320(ra) # 80001104 <mappages>
    80001be4:	02054163          	bltz	a0,80001c06 <proc_pagetable+0x76>
}
    80001be8:	8526                	mv	a0,s1
    80001bea:	60e2                	ld	ra,24(sp)
    80001bec:	6442                	ld	s0,16(sp)
    80001bee:	64a2                	ld	s1,8(sp)
    80001bf0:	6902                	ld	s2,0(sp)
    80001bf2:	6105                	addi	sp,sp,32
    80001bf4:	8082                	ret
    uvmfree(pagetable, 0);
    80001bf6:	4581                	li	a1,0
    80001bf8:	8526                	mv	a0,s1
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	998080e7          	jalr	-1640(ra) # 80001592 <uvmfree>
    return 0;
    80001c02:	4481                	li	s1,0
    80001c04:	b7d5                	j	80001be8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c06:	4681                	li	a3,0
    80001c08:	4605                	li	a2,1
    80001c0a:	040005b7          	lui	a1,0x4000
    80001c0e:	15fd                	addi	a1,a1,-1
    80001c10:	05b2                	slli	a1,a1,0xc
    80001c12:	8526                	mv	a0,s1
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	6b6080e7          	jalr	1718(ra) # 800012ca <uvmunmap>
    uvmfree(pagetable, 0);
    80001c1c:	4581                	li	a1,0
    80001c1e:	8526                	mv	a0,s1
    80001c20:	00000097          	auipc	ra,0x0
    80001c24:	972080e7          	jalr	-1678(ra) # 80001592 <uvmfree>
    return 0;
    80001c28:	4481                	li	s1,0
    80001c2a:	bf7d                	j	80001be8 <proc_pagetable+0x58>

0000000080001c2c <proc_freepagetable>:
{
    80001c2c:	1101                	addi	sp,sp,-32
    80001c2e:	ec06                	sd	ra,24(sp)
    80001c30:	e822                	sd	s0,16(sp)
    80001c32:	e426                	sd	s1,8(sp)
    80001c34:	e04a                	sd	s2,0(sp)
    80001c36:	1000                	addi	s0,sp,32
    80001c38:	84aa                	mv	s1,a0
    80001c3a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c3c:	4681                	li	a3,0
    80001c3e:	4605                	li	a2,1
    80001c40:	040005b7          	lui	a1,0x4000
    80001c44:	15fd                	addi	a1,a1,-1
    80001c46:	05b2                	slli	a1,a1,0xc
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	682080e7          	jalr	1666(ra) # 800012ca <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c50:	4681                	li	a3,0
    80001c52:	4605                	li	a2,1
    80001c54:	020005b7          	lui	a1,0x2000
    80001c58:	15fd                	addi	a1,a1,-1
    80001c5a:	05b6                	slli	a1,a1,0xd
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	66c080e7          	jalr	1644(ra) # 800012ca <uvmunmap>
  uvmfree(pagetable, sz);
    80001c66:	85ca                	mv	a1,s2
    80001c68:	8526                	mv	a0,s1
    80001c6a:	00000097          	auipc	ra,0x0
    80001c6e:	928080e7          	jalr	-1752(ra) # 80001592 <uvmfree>
}
    80001c72:	60e2                	ld	ra,24(sp)
    80001c74:	6442                	ld	s0,16(sp)
    80001c76:	64a2                	ld	s1,8(sp)
    80001c78:	6902                	ld	s2,0(sp)
    80001c7a:	6105                	addi	sp,sp,32
    80001c7c:	8082                	ret

0000000080001c7e <freeproc>:
{
    80001c7e:	1101                	addi	sp,sp,-32
    80001c80:	ec06                	sd	ra,24(sp)
    80001c82:	e822                	sd	s0,16(sp)
    80001c84:	e426                	sd	s1,8(sp)
    80001c86:	1000                	addi	s0,sp,32
    80001c88:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001c8a:	6d28                	ld	a0,88(a0)
    80001c8c:	c509                	beqz	a0,80001c96 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	d5c080e7          	jalr	-676(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001c96:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001c9a:	68a8                	ld	a0,80(s1)
    80001c9c:	c511                	beqz	a0,80001ca8 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c9e:	64ac                	ld	a1,72(s1)
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	f8c080e7          	jalr	-116(ra) # 80001c2c <proc_freepagetable>
  p->pagetable = 0;
    80001ca8:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cac:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cb0:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001cb4:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001cb8:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cbc:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cc0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cc4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cc8:	0004ac23          	sw	zero,24(s1)
}
    80001ccc:	60e2                	ld	ra,24(sp)
    80001cce:	6442                	ld	s0,16(sp)
    80001cd0:	64a2                	ld	s1,8(sp)
    80001cd2:	6105                	addi	sp,sp,32
    80001cd4:	8082                	ret

0000000080001cd6 <allocproc>:
{
    80001cd6:	1101                	addi	sp,sp,-32
    80001cd8:	ec06                	sd	ra,24(sp)
    80001cda:	e822                	sd	s0,16(sp)
    80001cdc:	e426                	sd	s1,8(sp)
    80001cde:	e04a                	sd	s2,0(sp)
    80001ce0:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001ce2:	0022f497          	auipc	s1,0x22f
    80001ce6:	2b648493          	addi	s1,s1,694 # 80230f98 <proc>
    80001cea:	00236917          	auipc	s2,0x236
    80001cee:	8ae90913          	addi	s2,s2,-1874 # 80237598 <tickslock>
    acquire(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	f48080e7          	jalr	-184(ra) # 80000c3c <acquire>
    if (p->state == UNUSED)
    80001cfc:	4c9c                	lw	a5,24(s1)
    80001cfe:	cf81                	beqz	a5,80001d16 <allocproc+0x40>
      release(&p->lock);
    80001d00:	8526                	mv	a0,s1
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	fee080e7          	jalr	-18(ra) # 80000cf0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d0a:	19848493          	addi	s1,s1,408
    80001d0e:	ff2492e3          	bne	s1,s2,80001cf2 <allocproc+0x1c>
  return 0;
    80001d12:	4481                	li	s1,0
    80001d14:	a861                	j	80001dac <allocproc+0xd6>
  p->pid = allocpid();
    80001d16:	00000097          	auipc	ra,0x0
    80001d1a:	e34080e7          	jalr	-460(ra) # 80001b4a <allocpid>
    80001d1e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d20:	4785                	li	a5,1
    80001d22:	cc9c                	sw	a5,24(s1)
  p->rbi = 25;
    80001d24:	47e5                	li	a5,25
    80001d26:	16f4ae23          	sw	a5,380(s1)
  p->sp = 50;
    80001d2a:	03200793          	li	a5,50
    80001d2e:	16f4aa23          	sw	a5,372(s1)
  p->dp=75;
    80001d32:	04b00793          	li	a5,75
    80001d36:	16f4ac23          	sw	a5,376(s1)
  p->runtime = 0;
    80001d3a:	1804a023          	sw	zero,384(s1)
  p->stime = 0;
    80001d3e:	1804a223          	sw	zero,388(s1)
  p->wtime = 0;
    80001d42:	1804a423          	sw	zero,392(s1)
  p->no_scheduled = 0;
    80001d46:	1804a823          	sw	zero,400(s1)
  p->start_time = ticks;
    80001d4a:	00007797          	auipc	a5,0x7
    80001d4e:	b967a783          	lw	a5,-1130(a5) # 800088e0 <ticks>
    80001d52:	18f4aa23          	sw	a5,404(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	dd6080e7          	jalr	-554(ra) # 80000b2c <kalloc>
    80001d5e:	892a                	mv	s2,a0
    80001d60:	eca8                	sd	a0,88(s1)
    80001d62:	cd21                	beqz	a0,80001dba <allocproc+0xe4>
  p->pagetable = proc_pagetable(p);
    80001d64:	8526                	mv	a0,s1
    80001d66:	00000097          	auipc	ra,0x0
    80001d6a:	e2a080e7          	jalr	-470(ra) # 80001b90 <proc_pagetable>
    80001d6e:	892a                	mv	s2,a0
    80001d70:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001d72:	c125                	beqz	a0,80001dd2 <allocproc+0xfc>
  memset(&p->context, 0, sizeof(p->context));
    80001d74:	07000613          	li	a2,112
    80001d78:	4581                	li	a1,0
    80001d7a:	06048513          	addi	a0,s1,96
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	fba080e7          	jalr	-70(ra) # 80000d38 <memset>
  p->context.ra = (uint64)forkret;
    80001d86:	00000797          	auipc	a5,0x0
    80001d8a:	d7e78793          	addi	a5,a5,-642 # 80001b04 <forkret>
    80001d8e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d90:	60bc                	ld	a5,64(s1)
    80001d92:	6705                	lui	a4,0x1
    80001d94:	97ba                	add	a5,a5,a4
    80001d96:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001d98:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001d9c:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001da0:	00007797          	auipc	a5,0x7
    80001da4:	b407a783          	lw	a5,-1216(a5) # 800088e0 <ticks>
    80001da8:	16f4a623          	sw	a5,364(s1)
}
    80001dac:	8526                	mv	a0,s1
    80001dae:	60e2                	ld	ra,24(sp)
    80001db0:	6442                	ld	s0,16(sp)
    80001db2:	64a2                	ld	s1,8(sp)
    80001db4:	6902                	ld	s2,0(sp)
    80001db6:	6105                	addi	sp,sp,32
    80001db8:	8082                	ret
    freeproc(p);
    80001dba:	8526                	mv	a0,s1
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	ec2080e7          	jalr	-318(ra) # 80001c7e <freeproc>
    release(&p->lock);
    80001dc4:	8526                	mv	a0,s1
    80001dc6:	fffff097          	auipc	ra,0xfffff
    80001dca:	f2a080e7          	jalr	-214(ra) # 80000cf0 <release>
    return 0;
    80001dce:	84ca                	mv	s1,s2
    80001dd0:	bff1                	j	80001dac <allocproc+0xd6>
    freeproc(p);
    80001dd2:	8526                	mv	a0,s1
    80001dd4:	00000097          	auipc	ra,0x0
    80001dd8:	eaa080e7          	jalr	-342(ra) # 80001c7e <freeproc>
    release(&p->lock);
    80001ddc:	8526                	mv	a0,s1
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	f12080e7          	jalr	-238(ra) # 80000cf0 <release>
    return 0;
    80001de6:	84ca                	mv	s1,s2
    80001de8:	b7d1                	j	80001dac <allocproc+0xd6>

0000000080001dea <userinit>:
{
    80001dea:	1101                	addi	sp,sp,-32
    80001dec:	ec06                	sd	ra,24(sp)
    80001dee:	e822                	sd	s0,16(sp)
    80001df0:	e426                	sd	s1,8(sp)
    80001df2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001df4:	00000097          	auipc	ra,0x0
    80001df8:	ee2080e7          	jalr	-286(ra) # 80001cd6 <allocproc>
    80001dfc:	84aa                	mv	s1,a0
  initproc = p;
    80001dfe:	00007797          	auipc	a5,0x7
    80001e02:	aca7bd23          	sd	a0,-1318(a5) # 800088d8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e06:	03400613          	li	a2,52
    80001e0a:	00007597          	auipc	a1,0x7
    80001e0e:	a6658593          	addi	a1,a1,-1434 # 80008870 <initcode>
    80001e12:	6928                	ld	a0,80(a0)
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	5a8080e7          	jalr	1448(ra) # 800013bc <uvmfirst>
  p->sz = PGSIZE;
    80001e1c:	6785                	lui	a5,0x1
    80001e1e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e20:	6cb8                	ld	a4,88(s1)
    80001e22:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e26:	6cb8                	ld	a4,88(s1)
    80001e28:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e2a:	4641                	li	a2,16
    80001e2c:	00006597          	auipc	a1,0x6
    80001e30:	3d458593          	addi	a1,a1,980 # 80008200 <digits+0x1c0>
    80001e34:	15848513          	addi	a0,s1,344
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	04a080e7          	jalr	74(ra) # 80000e82 <safestrcpy>
  p->cwd = namei("/");
    80001e40:	00006517          	auipc	a0,0x6
    80001e44:	3d050513          	addi	a0,a0,976 # 80008210 <digits+0x1d0>
    80001e48:	00002097          	auipc	ra,0x2
    80001e4c:	794080e7          	jalr	1940(ra) # 800045dc <namei>
    80001e50:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e54:	478d                	li	a5,3
    80001e56:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	e96080e7          	jalr	-362(ra) # 80000cf0 <release>
}
    80001e62:	60e2                	ld	ra,24(sp)
    80001e64:	6442                	ld	s0,16(sp)
    80001e66:	64a2                	ld	s1,8(sp)
    80001e68:	6105                	addi	sp,sp,32
    80001e6a:	8082                	ret

0000000080001e6c <growproc>:
{
    80001e6c:	1101                	addi	sp,sp,-32
    80001e6e:	ec06                	sd	ra,24(sp)
    80001e70:	e822                	sd	s0,16(sp)
    80001e72:	e426                	sd	s1,8(sp)
    80001e74:	e04a                	sd	s2,0(sp)
    80001e76:	1000                	addi	s0,sp,32
    80001e78:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e7a:	00000097          	auipc	ra,0x0
    80001e7e:	c52080e7          	jalr	-942(ra) # 80001acc <myproc>
    80001e82:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e84:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001e86:	01204c63          	bgtz	s2,80001e9e <growproc+0x32>
  else if (n < 0)
    80001e8a:	02094663          	bltz	s2,80001eb6 <growproc+0x4a>
  p->sz = sz;
    80001e8e:	e4ac                	sd	a1,72(s1)
  return 0;
    80001e90:	4501                	li	a0,0
}
    80001e92:	60e2                	ld	ra,24(sp)
    80001e94:	6442                	ld	s0,16(sp)
    80001e96:	64a2                	ld	s1,8(sp)
    80001e98:	6902                	ld	s2,0(sp)
    80001e9a:	6105                	addi	sp,sp,32
    80001e9c:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001e9e:	4691                	li	a3,4
    80001ea0:	00b90633          	add	a2,s2,a1
    80001ea4:	6928                	ld	a0,80(a0)
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	5d0080e7          	jalr	1488(ra) # 80001476 <uvmalloc>
    80001eae:	85aa                	mv	a1,a0
    80001eb0:	fd79                	bnez	a0,80001e8e <growproc+0x22>
      return -1;
    80001eb2:	557d                	li	a0,-1
    80001eb4:	bff9                	j	80001e92 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001eb6:	00b90633          	add	a2,s2,a1
    80001eba:	6928                	ld	a0,80(a0)
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	572080e7          	jalr	1394(ra) # 8000142e <uvmdealloc>
    80001ec4:	85aa                	mv	a1,a0
    80001ec6:	b7e1                	j	80001e8e <growproc+0x22>

0000000080001ec8 <fork>:
{
    80001ec8:	7139                	addi	sp,sp,-64
    80001eca:	fc06                	sd	ra,56(sp)
    80001ecc:	f822                	sd	s0,48(sp)
    80001ece:	f426                	sd	s1,40(sp)
    80001ed0:	f04a                	sd	s2,32(sp)
    80001ed2:	ec4e                	sd	s3,24(sp)
    80001ed4:	e852                	sd	s4,16(sp)
    80001ed6:	e456                	sd	s5,8(sp)
    80001ed8:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001eda:	00000097          	auipc	ra,0x0
    80001ede:	bf2080e7          	jalr	-1038(ra) # 80001acc <myproc>
    80001ee2:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001ee4:	00000097          	auipc	ra,0x0
    80001ee8:	df2080e7          	jalr	-526(ra) # 80001cd6 <allocproc>
    80001eec:	10050c63          	beqz	a0,80002004 <fork+0x13c>
    80001ef0:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001ef2:	048ab603          	ld	a2,72(s5)
    80001ef6:	692c                	ld	a1,80(a0)
    80001ef8:	050ab503          	ld	a0,80(s5)
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	6ce080e7          	jalr	1742(ra) # 800015ca <uvmcopy>
    80001f04:	04054863          	bltz	a0,80001f54 <fork+0x8c>
  np->sz = p->sz;
    80001f08:	048ab783          	ld	a5,72(s5)
    80001f0c:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001f10:	058ab683          	ld	a3,88(s5)
    80001f14:	87b6                	mv	a5,a3
    80001f16:	058a3703          	ld	a4,88(s4)
    80001f1a:	12068693          	addi	a3,a3,288
    80001f1e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f22:	6788                	ld	a0,8(a5)
    80001f24:	6b8c                	ld	a1,16(a5)
    80001f26:	6f90                	ld	a2,24(a5)
    80001f28:	01073023          	sd	a6,0(a4)
    80001f2c:	e708                	sd	a0,8(a4)
    80001f2e:	eb0c                	sd	a1,16(a4)
    80001f30:	ef10                	sd	a2,24(a4)
    80001f32:	02078793          	addi	a5,a5,32
    80001f36:	02070713          	addi	a4,a4,32
    80001f3a:	fed792e3          	bne	a5,a3,80001f1e <fork+0x56>
  np->trapframe->a0 = 0;
    80001f3e:	058a3783          	ld	a5,88(s4)
    80001f42:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001f46:	0d0a8493          	addi	s1,s5,208
    80001f4a:	0d0a0913          	addi	s2,s4,208
    80001f4e:	150a8993          	addi	s3,s5,336
    80001f52:	a00d                	j	80001f74 <fork+0xac>
    freeproc(np);
    80001f54:	8552                	mv	a0,s4
    80001f56:	00000097          	auipc	ra,0x0
    80001f5a:	d28080e7          	jalr	-728(ra) # 80001c7e <freeproc>
    release(&np->lock);
    80001f5e:	8552                	mv	a0,s4
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	d90080e7          	jalr	-624(ra) # 80000cf0 <release>
    return -1;
    80001f68:	597d                	li	s2,-1
    80001f6a:	a059                	j	80001ff0 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001f6c:	04a1                	addi	s1,s1,8
    80001f6e:	0921                	addi	s2,s2,8
    80001f70:	01348b63          	beq	s1,s3,80001f86 <fork+0xbe>
    if (p->ofile[i])
    80001f74:	6088                	ld	a0,0(s1)
    80001f76:	d97d                	beqz	a0,80001f6c <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f78:	00003097          	auipc	ra,0x3
    80001f7c:	cfa080e7          	jalr	-774(ra) # 80004c72 <filedup>
    80001f80:	00a93023          	sd	a0,0(s2)
    80001f84:	b7e5                	j	80001f6c <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001f86:	150ab503          	ld	a0,336(s5)
    80001f8a:	00002097          	auipc	ra,0x2
    80001f8e:	e6e080e7          	jalr	-402(ra) # 80003df8 <idup>
    80001f92:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f96:	4641                	li	a2,16
    80001f98:	158a8593          	addi	a1,s5,344
    80001f9c:	158a0513          	addi	a0,s4,344
    80001fa0:	fffff097          	auipc	ra,0xfffff
    80001fa4:	ee2080e7          	jalr	-286(ra) # 80000e82 <safestrcpy>
  pid = np->pid;
    80001fa8:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001fac:	8552                	mv	a0,s4
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	d42080e7          	jalr	-702(ra) # 80000cf0 <release>
  acquire(&wait_lock);
    80001fb6:	0022f497          	auipc	s1,0x22f
    80001fba:	bca48493          	addi	s1,s1,-1078 # 80230b80 <wait_lock>
    80001fbe:	8526                	mv	a0,s1
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	c7c080e7          	jalr	-900(ra) # 80000c3c <acquire>
  np->parent = p;
    80001fc8:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001fcc:	8526                	mv	a0,s1
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	d22080e7          	jalr	-734(ra) # 80000cf0 <release>
  acquire(&np->lock);
    80001fd6:	8552                	mv	a0,s4
    80001fd8:	fffff097          	auipc	ra,0xfffff
    80001fdc:	c64080e7          	jalr	-924(ra) # 80000c3c <acquire>
  np->state = RUNNABLE;
    80001fe0:	478d                	li	a5,3
    80001fe2:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001fe6:	8552                	mv	a0,s4
    80001fe8:	fffff097          	auipc	ra,0xfffff
    80001fec:	d08080e7          	jalr	-760(ra) # 80000cf0 <release>
}
    80001ff0:	854a                	mv	a0,s2
    80001ff2:	70e2                	ld	ra,56(sp)
    80001ff4:	7442                	ld	s0,48(sp)
    80001ff6:	74a2                	ld	s1,40(sp)
    80001ff8:	7902                	ld	s2,32(sp)
    80001ffa:	69e2                	ld	s3,24(sp)
    80001ffc:	6a42                	ld	s4,16(sp)
    80001ffe:	6aa2                	ld	s5,8(sp)
    80002000:	6121                	addi	sp,sp,64
    80002002:	8082                	ret
    return -1;
    80002004:	597d                	li	s2,-1
    80002006:	b7ed                	j	80001ff0 <fork+0x128>

0000000080002008 <scheduler>:
{
    80002008:	b8010113          	addi	sp,sp,-1152
    8000200c:	46113c23          	sd	ra,1144(sp)
    80002010:	46813823          	sd	s0,1136(sp)
    80002014:	46913423          	sd	s1,1128(sp)
    80002018:	47213023          	sd	s2,1120(sp)
    8000201c:	45313c23          	sd	s3,1112(sp)
    80002020:	45413823          	sd	s4,1104(sp)
    80002024:	45513423          	sd	s5,1096(sp)
    80002028:	45613023          	sd	s6,1088(sp)
    8000202c:	43713c23          	sd	s7,1080(sp)
    80002030:	43813823          	sd	s8,1072(sp)
    80002034:	43913423          	sd	s9,1064(sp)
    80002038:	43a13023          	sd	s10,1056(sp)
    8000203c:	41b13c23          	sd	s11,1048(sp)
    80002040:	48010413          	addi	s0,sp,1152
    80002044:	8792                	mv	a5,tp
  int id = r_tp();
    80002046:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002048:	00779693          	slli	a3,a5,0x7
    8000204c:	0022f717          	auipc	a4,0x22f
    80002050:	b1c70713          	addi	a4,a4,-1252 # 80230b68 <pid_lock>
    80002054:	9736                	add	a4,a4,a3
    80002056:	02073823          	sd	zero,48(a4)
            swtch(&c->context, &p->context);
    8000205a:	0022f717          	auipc	a4,0x22f
    8000205e:	b4670713          	addi	a4,a4,-1210 # 80230ba0 <cpus+0x8>
    80002062:	9736                	add	a4,a4,a3
    80002064:	b8e43023          	sd	a4,-1152(s0)
    int max = 0;
    80002068:	4c01                	li	s8,0
      if (p->state == RUNNABLE)
    8000206a:	448d                	li	s1,3
        p->dp = (p->sp + p->rbi) < 100 ? (p->sp + p->rbi) : 100;
    8000206c:	06400a93          	li	s5,100
    for (p = proc; p < &proc[NPROC]; p++)
    80002070:	00235917          	auipc	s2,0x235
    80002074:	52890913          	addi	s2,s2,1320 # 80237598 <tickslock>
            c->proc = p;
    80002078:	0022fc97          	auipc	s9,0x22f
    8000207c:	af0c8c93          	addi	s9,s9,-1296 # 80230b68 <pid_lock>
    80002080:	9cb6                	add	s9,s9,a3
    80002082:	a25d                	j	80002228 <scheduler+0x220>
    80002084:	00070b1b          	sext.w	s6,a4
      release(&p->lock);
    80002088:	854e                	mv	a0,s3
    8000208a:	fffff097          	auipc	ra,0xfffff
    8000208e:	c66080e7          	jalr	-922(ra) # 80000cf0 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002092:	19898993          	addi	s3,s3,408
    80002096:	07298563          	beq	s3,s2,80002100 <scheduler+0xf8>
      acquire(&p->lock);
    8000209a:	854e                	mv	a0,s3
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	ba0080e7          	jalr	-1120(ra) # 80000c3c <acquire>
      if (p->state == RUNNABLE)
    800020a4:	0189a783          	lw	a5,24(s3)
    800020a8:	fe9790e3          	bne	a5,s1,80002088 <scheduler+0x80>
        int a = (3 * p->runtime - p->stime - p->wtime) * 50;
    800020ac:	1809a703          	lw	a4,384(s3)
    800020b0:	1849a603          	lw	a2,388(s3)
    800020b4:	1889a683          	lw	a3,392(s3)
    800020b8:	0017179b          	slliw	a5,a4,0x1
    800020bc:	9fb9                	addw	a5,a5,a4
    800020be:	9f91                	subw	a5,a5,a2
    800020c0:	9f95                	subw	a5,a5,a3
    800020c2:	037787bb          	mulw	a5,a5,s7
        double b = a / (p->runtime + p->stime + p->wtime + 1);
    800020c6:	9f31                	addw	a4,a4,a2
    800020c8:	9f35                	addw	a4,a4,a3
    800020ca:	2705                	addiw	a4,a4,1
    800020cc:	02e7c7bb          	divw	a5,a5,a4
        p->rbi = c > 0 ? c : 0;
    800020d0:	0007871b          	sext.w	a4,a5
    800020d4:	fff74713          	not	a4,a4
    800020d8:	977d                	srai	a4,a4,0x3f
    800020da:	8ff9                	and	a5,a5,a4
    800020dc:	16f9ae23          	sw	a5,380(s3)
        p->dp = (p->sp + p->rbi) < 100 ? (p->sp + p->rbi) : 100;
    800020e0:	1749a703          	lw	a4,372(s3)
    800020e4:	9fb9                	addw	a5,a5,a4
    800020e6:	0007871b          	sext.w	a4,a5
    800020ea:	00ea5363          	bge	s4,a4,800020f0 <scheduler+0xe8>
    800020ee:	87d6                	mv	a5,s5
    800020f0:	16f9ac23          	sw	a5,376(s3)
        if (p->dp > max)
    800020f4:	873e                	mv	a4,a5
    800020f6:	2781                	sext.w	a5,a5
    800020f8:	f967d6e3          	bge	a5,s6,80002084 <scheduler+0x7c>
    800020fc:	875a                	mv	a4,s6
    800020fe:	b759                	j	80002084 <scheduler+0x7c>
    int count = 0;
    80002100:	8be2                	mv	s7,s8
     int arrind = 0;
    80002102:	89e2                	mv	s3,s8
    for (p = proc; p < &proc[NPROC]; p++)
    80002104:	0022fa17          	auipc	s4,0x22f
    80002108:	e94a0a13          	addi	s4,s4,-364 # 80230f98 <proc>
    8000210c:	a811                	j	80002120 <scheduler+0x118>
      release(&p->lock);
    8000210e:	8552                	mv	a0,s4
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	be0080e7          	jalr	-1056(ra) # 80000cf0 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002118:	198a0a13          	addi	s4,s4,408
    8000211c:	032a0963          	beq	s4,s2,8000214e <scheduler+0x146>
      acquire(&p->lock);
    80002120:	8552                	mv	a0,s4
    80002122:	fffff097          	auipc	ra,0xfffff
    80002126:	b1a080e7          	jalr	-1254(ra) # 80000c3c <acquire>
      if (p->state == RUNNABLE)
    8000212a:	018a2783          	lw	a5,24(s4)
    8000212e:	fe9790e3          	bne	a5,s1,8000210e <scheduler+0x106>
        if (p->dp == max)
    80002132:	178a2783          	lw	a5,376(s4)
    80002136:	fd679ce3          	bne	a5,s6,8000210e <scheduler+0x106>
          count++;
    8000213a:	2b85                	addiw	s7,s7,1
          arr[arrind++] = p;
    8000213c:	00399793          	slli	a5,s3,0x3
    80002140:	f9040713          	addi	a4,s0,-112
    80002144:	97ba                	add	a5,a5,a4
    80002146:	c147b023          	sd	s4,-1024(a5)
    8000214a:	2985                	addiw	s3,s3,1
    8000214c:	b7c9                	j	8000210e <scheduler+0x106>
    if (count != 0)
    8000214e:	220b8363          	beqz	s7,80002374 <scheduler+0x36c>
      int no_sched = arr[0]->no_scheduled;
    80002152:	b9043783          	ld	a5,-1136(s0)
    80002156:	1907ab83          	lw	s7,400(a5)
      for (int i = 0; i < arrind; i++)
    8000215a:	0d305763          	blez	s3,80002228 <scheduler+0x220>
    8000215e:	b9040b13          	addi	s6,s0,-1136
    80002162:	8dda                	mv	s11,s6
    80002164:	8d62                	mv	s10,s8
      int ind = 0;
    80002166:	b9843423          	sd	s8,-1144(s0)
    8000216a:	a811                	j	8000217e <scheduler+0x176>
        release(&arr[i]->lock);
    8000216c:	8552                	mv	a0,s4
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	b82080e7          	jalr	-1150(ra) # 80000cf0 <release>
      for (int i = 0; i < arrind; i++)
    80002176:	2d05                	addiw	s10,s10,1
    80002178:	0da1                	addi	s11,s11,8
    8000217a:	03a98563          	beq	s3,s10,800021a4 <scheduler+0x19c>
        acquire(&arr[i]->lock);
    8000217e:	000dba03          	ld	s4,0(s11)
    80002182:	8552                	mv	a0,s4
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	ab8080e7          	jalr	-1352(ra) # 80000c3c <acquire>
        if (arr[i]->state == RUNNABLE)
    8000218c:	018a2783          	lw	a5,24(s4)
    80002190:	fc979ee3          	bne	a5,s1,8000216c <scheduler+0x164>
          if (arr[i]->no_scheduled < no_sched)
    80002194:	190a2783          	lw	a5,400(s4)
    80002198:	fd77dae3          	bge	a5,s7,8000216c <scheduler+0x164>
    8000219c:	b9a43423          	sd	s10,-1144(s0)
            no_sched = arr[i]->no_scheduled;
    800021a0:	8bbe                	mv	s7,a5
    800021a2:	b7e9                	j	8000216c <scheduler+0x164>
    800021a4:	39fd                	addiw	s3,s3,-1
    800021a6:	1982                	slli	s3,s3,0x20
    800021a8:	0209d993          	srli	s3,s3,0x20
    800021ac:	098e                	slli	s3,s3,0x3
    800021ae:	008b0793          	addi	a5,s6,8
    800021b2:	99be                	add	s3,s3,a5
      for (int i = 0; i < arrind; i++)
    800021b4:	8d5a                	mv	s10,s6
    800021b6:	8de2                	mv	s11,s8
    800021b8:	a809                	j	800021ca <scheduler+0x1c2>
        release(&arr[i]->lock);
    800021ba:	8552                	mv	a0,s4
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	b34080e7          	jalr	-1228(ra) # 80000cf0 <release>
      for (int i = 0; i < arrind; i++)
    800021c4:	0d21                	addi	s10,s10,8
    800021c6:	033d0363          	beq	s10,s3,800021ec <scheduler+0x1e4>
        acquire(&arr[i]->lock);
    800021ca:	000d3a03          	ld	s4,0(s10)
    800021ce:	8552                	mv	a0,s4
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	a6c080e7          	jalr	-1428(ra) # 80000c3c <acquire>
        if (arr[i]->state == RUNNABLE)
    800021d8:	018a2783          	lw	a5,24(s4)
    800021dc:	fc979fe3          	bne	a5,s1,800021ba <scheduler+0x1b2>
          if (arr[i]->no_scheduled == no_sched)
    800021e0:	190a2783          	lw	a5,400(s4)
    800021e4:	fd779be3          	bne	a5,s7,800021ba <scheduler+0x1b2>
            count_sched++;
    800021e8:	2d85                	addiw	s11,s11,1
    800021ea:	bfc1                	j	800021ba <scheduler+0x1b2>
      if (count_sched == 1)
    800021ec:	4785                	li	a5,1
    800021ee:	00fd8763          	beq	s11,a5,800021fc <scheduler+0x1f4>
      else if (count_sched > 1)
    800021f2:	4785                	li	a5,1
    800021f4:	03b7da63          	bge	a5,s11,80002228 <scheduler+0x220>
        int arr2ind = 0;
    800021f8:	8a62                	mv	s4,s8
    800021fa:	a851                	j	8000228e <scheduler+0x286>
        struct proc *p3 = arr[ind];
    800021fc:	b8843783          	ld	a5,-1144(s0)
    80002200:	078e                	slli	a5,a5,0x3
    80002202:	f9040713          	addi	a4,s0,-112
    80002206:	97ba                	add	a5,a5,a4
    80002208:	c007b983          	ld	s3,-1024(a5)
        acquire(&p3->lock);
    8000220c:	854e                	mv	a0,s3
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	a2e080e7          	jalr	-1490(ra) # 80000c3c <acquire>
        if (p3->state == RUNNABLE)
    80002216:	0189a783          	lw	a5,24(s3)
    8000221a:	02978763          	beq	a5,s1,80002248 <scheduler+0x240>
        release(&p3->lock);
    8000221e:	854e                	mv	a0,s3
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	ad0080e7          	jalr	-1328(ra) # 80000cf0 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002228:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000222c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002230:	10079073          	csrw	sstatus,a5
    int max = 0;
    80002234:	8b62                	mv	s6,s8
    for (p = proc; p < &proc[NPROC]; p++)
    80002236:	0022f997          	auipc	s3,0x22f
    8000223a:	d6298993          	addi	s3,s3,-670 # 80230f98 <proc>
        int a = (3 * p->runtime - p->stime - p->wtime) * 50;
    8000223e:	03200b93          	li	s7,50
        p->dp = (p->sp + p->rbi) < 100 ? (p->sp + p->rbi) : 100;
    80002242:	06400a13          	li	s4,100
    80002246:	bd91                	j	8000209a <scheduler+0x92>
          p3->no_scheduled++;
    80002248:	1909a783          	lw	a5,400(s3)
    8000224c:	2785                	addiw	a5,a5,1
    8000224e:	18f9a823          	sw	a5,400(s3)
          p3->wtime = 0;
    80002252:	1809a423          	sw	zero,392(s3)
          p3->stime = 0;
    80002256:	1809a223          	sw	zero,388(s3)
          p3->rtime = 0;
    8000225a:	1609a423          	sw	zero,360(s3)
          p3->state = RUNNING;
    8000225e:	4791                	li	a5,4
    80002260:	00f9ac23          	sw	a5,24(s3)
          c->proc = p3;
    80002264:	033cb823          	sd	s3,48(s9)
          swtch(&c->context, &p3->context);
    80002268:	06098593          	addi	a1,s3,96
    8000226c:	b8043503          	ld	a0,-1152(s0)
    80002270:	00001097          	auipc	ra,0x1
    80002274:	9ce080e7          	jalr	-1586(ra) # 80002c3e <swtch>
          c->proc = 0;
    80002278:	020cb823          	sd	zero,48(s9)
    8000227c:	b74d                	j	8000221e <scheduler+0x216>
          release(&arr[i]->lock);
    8000227e:	856a                	mv	a0,s10
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	a70080e7          	jalr	-1424(ra) # 80000cf0 <release>
        for (int i = 0; i < arrind; i++)
    80002288:	0b21                	addi	s6,s6,8
    8000228a:	03698a63          	beq	s3,s6,800022be <scheduler+0x2b6>
          acquire(&arr[i]->lock);
    8000228e:	000b3d03          	ld	s10,0(s6)
    80002292:	856a                	mv	a0,s10
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	9a8080e7          	jalr	-1624(ra) # 80000c3c <acquire>
          if (arr[i]->state == RUNNABLE)
    8000229c:	018d2783          	lw	a5,24(s10)
    800022a0:	fc979fe3          	bne	a5,s1,8000227e <scheduler+0x276>
            if (arr[i]->no_scheduled == no_sched)
    800022a4:	190d2783          	lw	a5,400(s10)
    800022a8:	fd779be3          	bne	a5,s7,8000227e <scheduler+0x276>
              arr2[arr2ind++] = arr[i];
    800022ac:	003a1793          	slli	a5,s4,0x3
    800022b0:	f9040713          	addi	a4,s0,-112
    800022b4:	97ba                	add	a5,a5,a4
    800022b6:	e1a7b023          	sd	s10,-512(a5)
    800022ba:	2a05                	addiw	s4,s4,1
    800022bc:	b7c9                	j	8000227e <scheduler+0x276>
        int min_start = arr2[0]->start_time;
    800022be:	d9043783          	ld	a5,-624(s0)
    800022c2:	1947ad03          	lw	s10,404(a5)
        for (int i = 0; i < arr2ind; i++)
    800022c6:	05405563          	blez	s4,80002310 <scheduler+0x308>
    800022ca:	d9040b93          	addi	s7,s0,-624
    800022ce:	8b62                	mv	s6,s8
        int ind2 = 0;
    800022d0:	8de2                	mv	s11,s8
    800022d2:	a811                	j	800022e6 <scheduler+0x2de>
          release(&arr2[i]->lock);
    800022d4:	854e                	mv	a0,s3
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	a1a080e7          	jalr	-1510(ra) # 80000cf0 <release>
        for (int i = 0; i < arr2ind; i++)
    800022de:	2b05                	addiw	s6,s6,1
    800022e0:	0ba1                	addi	s7,s7,8
    800022e2:	036a0863          	beq	s4,s6,80002312 <scheduler+0x30a>
          acquire(&arr2[i]->lock);
    800022e6:	000bb983          	ld	s3,0(s7) # fffffffffffff000 <end+0xffffffff7fdbc688>
    800022ea:	854e                	mv	a0,s3
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	950080e7          	jalr	-1712(ra) # 80000c3c <acquire>
          if (arr2[i]->state == RUNNABLE)
    800022f4:	0189a783          	lw	a5,24(s3)
    800022f8:	fc979ee3          	bne	a5,s1,800022d4 <scheduler+0x2cc>
            if (arr2[i]->ctime < min_start)
    800022fc:	16c9a783          	lw	a5,364(s3)
    80002300:	000d071b          	sext.w	a4,s10
    80002304:	fce7f8e3          	bgeu	a5,a4,800022d4 <scheduler+0x2cc>
              min_start = arr2[i]->ctime;
    80002308:	00078d1b          	sext.w	s10,a5
    8000230c:	8dda                	mv	s11,s6
    8000230e:	b7d9                	j	800022d4 <scheduler+0x2cc>
        int ind2 = 0;
    80002310:	8de2                	mv	s11,s8
        struct proc *p3 = arr2[ind2];
    80002312:	003d9793          	slli	a5,s11,0x3
    80002316:	f9040713          	addi	a4,s0,-112
    8000231a:	97ba                	add	a5,a5,a4
    8000231c:	e007b983          	ld	s3,-512(a5)
        acquire(&p3->lock);
    80002320:	854e                	mv	a0,s3
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	91a080e7          	jalr	-1766(ra) # 80000c3c <acquire>
        if (p3->state == RUNNABLE)
    8000232a:	0189a783          	lw	a5,24(s3)
    8000232e:	00978863          	beq	a5,s1,8000233e <scheduler+0x336>
        release(&p3->lock);
    80002332:	854e                	mv	a0,s3
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	9bc080e7          	jalr	-1604(ra) # 80000cf0 <release>
    8000233c:	b5f5                	j	80002228 <scheduler+0x220>
          p3->no_scheduled++;
    8000233e:	1909a783          	lw	a5,400(s3)
    80002342:	2785                	addiw	a5,a5,1
    80002344:	18f9a823          	sw	a5,400(s3)
          p3->wtime = 0;
    80002348:	1809a423          	sw	zero,392(s3)
          p3->stime = 0;
    8000234c:	1809a223          	sw	zero,388(s3)
          p3->rtime = 0;
    80002350:	1609a423          	sw	zero,360(s3)
          p3->state = RUNNING;
    80002354:	4791                	li	a5,4
    80002356:	00f9ac23          	sw	a5,24(s3)
          c->proc = p3;
    8000235a:	033cb823          	sd	s3,48(s9)
          swtch(&c->context, &p3->context);
    8000235e:	06098593          	addi	a1,s3,96
    80002362:	b8043503          	ld	a0,-1152(s0)
    80002366:	00001097          	auipc	ra,0x1
    8000236a:	8d8080e7          	jalr	-1832(ra) # 80002c3e <swtch>
          c->proc = 0;
    8000236e:	020cb823          	sd	zero,48(s9)
    80002372:	b7c1                	j	80002332 <scheduler+0x32a>
      for (p = proc; p < &proc[NPROC]; p++)
    80002374:	0022f997          	auipc	s3,0x22f
    80002378:	c2498993          	addi	s3,s3,-988 # 80230f98 <proc>
            p->state = RUNNING;
    8000237c:	4b91                	li	s7,4
    8000237e:	a811                	j	80002392 <scheduler+0x38a>
        release(&p->lock);
    80002380:	854e                	mv	a0,s3
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	96e080e7          	jalr	-1682(ra) # 80000cf0 <release>
      for (p = proc; p < &proc[NPROC]; p++)
    8000238a:	19898993          	addi	s3,s3,408
    8000238e:	e9298de3          	beq	s3,s2,80002228 <scheduler+0x220>
        acquire(&p->lock);
    80002392:	854e                	mv	a0,s3
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	8a8080e7          	jalr	-1880(ra) # 80000c3c <acquire>
        if (p->state == RUNNABLE)
    8000239c:	0189a783          	lw	a5,24(s3)
    800023a0:	fe9790e3          	bne	a5,s1,80002380 <scheduler+0x378>
          if (p->dp == max)
    800023a4:	1789a783          	lw	a5,376(s3)
    800023a8:	fd679ce3          	bne	a5,s6,80002380 <scheduler+0x378>
            p->no_scheduled++;
    800023ac:	1909a783          	lw	a5,400(s3)
    800023b0:	2785                	addiw	a5,a5,1
    800023b2:	18f9a823          	sw	a5,400(s3)
            p->wtime = 0;
    800023b6:	1809a423          	sw	zero,392(s3)
            p->stime = 0;
    800023ba:	1809a223          	sw	zero,388(s3)
            p->rtime = 0;
    800023be:	1609a423          	sw	zero,360(s3)
            p->state = RUNNING;
    800023c2:	0179ac23          	sw	s7,24(s3)
            c->proc = p;
    800023c6:	033cb823          	sd	s3,48(s9)
            swtch(&c->context, &p->context);
    800023ca:	06098593          	addi	a1,s3,96
    800023ce:	b8043503          	ld	a0,-1152(s0)
    800023d2:	00001097          	auipc	ra,0x1
    800023d6:	86c080e7          	jalr	-1940(ra) # 80002c3e <swtch>
            c->proc = 0;
    800023da:	020cb823          	sd	zero,48(s9)
    800023de:	b74d                	j	80002380 <scheduler+0x378>

00000000800023e0 <sched>:
{
    800023e0:	7179                	addi	sp,sp,-48
    800023e2:	f406                	sd	ra,40(sp)
    800023e4:	f022                	sd	s0,32(sp)
    800023e6:	ec26                	sd	s1,24(sp)
    800023e8:	e84a                	sd	s2,16(sp)
    800023ea:	e44e                	sd	s3,8(sp)
    800023ec:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	6de080e7          	jalr	1758(ra) # 80001acc <myproc>
    800023f6:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	7ca080e7          	jalr	1994(ra) # 80000bc2 <holding>
    80002400:	c93d                	beqz	a0,80002476 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002402:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002404:	2781                	sext.w	a5,a5
    80002406:	079e                	slli	a5,a5,0x7
    80002408:	0022e717          	auipc	a4,0x22e
    8000240c:	76070713          	addi	a4,a4,1888 # 80230b68 <pid_lock>
    80002410:	97ba                	add	a5,a5,a4
    80002412:	0a87a703          	lw	a4,168(a5)
    80002416:	4785                	li	a5,1
    80002418:	06f71763          	bne	a4,a5,80002486 <sched+0xa6>
  if (p->state == RUNNING)
    8000241c:	4c98                	lw	a4,24(s1)
    8000241e:	4791                	li	a5,4
    80002420:	06f70b63          	beq	a4,a5,80002496 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002424:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002428:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000242a:	efb5                	bnez	a5,800024a6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000242c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000242e:	0022e917          	auipc	s2,0x22e
    80002432:	73a90913          	addi	s2,s2,1850 # 80230b68 <pid_lock>
    80002436:	2781                	sext.w	a5,a5
    80002438:	079e                	slli	a5,a5,0x7
    8000243a:	97ca                	add	a5,a5,s2
    8000243c:	0ac7a983          	lw	s3,172(a5)
    80002440:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002442:	2781                	sext.w	a5,a5
    80002444:	079e                	slli	a5,a5,0x7
    80002446:	0022e597          	auipc	a1,0x22e
    8000244a:	75a58593          	addi	a1,a1,1882 # 80230ba0 <cpus+0x8>
    8000244e:	95be                	add	a1,a1,a5
    80002450:	06048513          	addi	a0,s1,96
    80002454:	00000097          	auipc	ra,0x0
    80002458:	7ea080e7          	jalr	2026(ra) # 80002c3e <swtch>
    8000245c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000245e:	2781                	sext.w	a5,a5
    80002460:	079e                	slli	a5,a5,0x7
    80002462:	97ca                	add	a5,a5,s2
    80002464:	0b37a623          	sw	s3,172(a5)
}
    80002468:	70a2                	ld	ra,40(sp)
    8000246a:	7402                	ld	s0,32(sp)
    8000246c:	64e2                	ld	s1,24(sp)
    8000246e:	6942                	ld	s2,16(sp)
    80002470:	69a2                	ld	s3,8(sp)
    80002472:	6145                	addi	sp,sp,48
    80002474:	8082                	ret
    panic("sched p->lock");
    80002476:	00006517          	auipc	a0,0x6
    8000247a:	da250513          	addi	a0,a0,-606 # 80008218 <digits+0x1d8>
    8000247e:	ffffe097          	auipc	ra,0xffffe
    80002482:	0c0080e7          	jalr	192(ra) # 8000053e <panic>
    panic("sched locks");
    80002486:	00006517          	auipc	a0,0x6
    8000248a:	da250513          	addi	a0,a0,-606 # 80008228 <digits+0x1e8>
    8000248e:	ffffe097          	auipc	ra,0xffffe
    80002492:	0b0080e7          	jalr	176(ra) # 8000053e <panic>
    panic("sched running");
    80002496:	00006517          	auipc	a0,0x6
    8000249a:	da250513          	addi	a0,a0,-606 # 80008238 <digits+0x1f8>
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	0a0080e7          	jalr	160(ra) # 8000053e <panic>
    panic("sched interruptible");
    800024a6:	00006517          	auipc	a0,0x6
    800024aa:	da250513          	addi	a0,a0,-606 # 80008248 <digits+0x208>
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	090080e7          	jalr	144(ra) # 8000053e <panic>

00000000800024b6 <yield>:
{
    800024b6:	1101                	addi	sp,sp,-32
    800024b8:	ec06                	sd	ra,24(sp)
    800024ba:	e822                	sd	s0,16(sp)
    800024bc:	e426                	sd	s1,8(sp)
    800024be:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	60c080e7          	jalr	1548(ra) # 80001acc <myproc>
    800024c8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024ca:	ffffe097          	auipc	ra,0xffffe
    800024ce:	772080e7          	jalr	1906(ra) # 80000c3c <acquire>
  p->state = RUNNABLE;
    800024d2:	478d                	li	a5,3
    800024d4:	cc9c                	sw	a5,24(s1)
  sched();
    800024d6:	00000097          	auipc	ra,0x0
    800024da:	f0a080e7          	jalr	-246(ra) # 800023e0 <sched>
  release(&p->lock);
    800024de:	8526                	mv	a0,s1
    800024e0:	fffff097          	auipc	ra,0xfffff
    800024e4:	810080e7          	jalr	-2032(ra) # 80000cf0 <release>
}
    800024e8:	60e2                	ld	ra,24(sp)
    800024ea:	6442                	ld	s0,16(sp)
    800024ec:	64a2                	ld	s1,8(sp)
    800024ee:	6105                	addi	sp,sp,32
    800024f0:	8082                	ret

00000000800024f2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800024f2:	7179                	addi	sp,sp,-48
    800024f4:	f406                	sd	ra,40(sp)
    800024f6:	f022                	sd	s0,32(sp)
    800024f8:	ec26                	sd	s1,24(sp)
    800024fa:	e84a                	sd	s2,16(sp)
    800024fc:	e44e                	sd	s3,8(sp)
    800024fe:	1800                	addi	s0,sp,48
    80002500:	89aa                	mv	s3,a0
    80002502:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002504:	fffff097          	auipc	ra,0xfffff
    80002508:	5c8080e7          	jalr	1480(ra) # 80001acc <myproc>
    8000250c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000250e:	ffffe097          	auipc	ra,0xffffe
    80002512:	72e080e7          	jalr	1838(ra) # 80000c3c <acquire>
  release(lk);
    80002516:	854a                	mv	a0,s2
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	7d8080e7          	jalr	2008(ra) # 80000cf0 <release>
  // Go to sleep.
  p->chan = chan;
    80002520:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002524:	4789                	li	a5,2
    80002526:	cc9c                	sw	a5,24(s1)
  // printf("#%d ",p->pid);
  sched();
    80002528:	00000097          	auipc	ra,0x0
    8000252c:	eb8080e7          	jalr	-328(ra) # 800023e0 <sched>

  // Tidy up.
  p->chan = 0;
    80002530:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002534:	8526                	mv	a0,s1
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	7ba080e7          	jalr	1978(ra) # 80000cf0 <release>
  acquire(lk);
    8000253e:	854a                	mv	a0,s2
    80002540:	ffffe097          	auipc	ra,0xffffe
    80002544:	6fc080e7          	jalr	1788(ra) # 80000c3c <acquire>
}
    80002548:	70a2                	ld	ra,40(sp)
    8000254a:	7402                	ld	s0,32(sp)
    8000254c:	64e2                	ld	s1,24(sp)
    8000254e:	6942                	ld	s2,16(sp)
    80002550:	69a2                	ld	s3,8(sp)
    80002552:	6145                	addi	sp,sp,48
    80002554:	8082                	ret

0000000080002556 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002556:	7139                	addi	sp,sp,-64
    80002558:	fc06                	sd	ra,56(sp)
    8000255a:	f822                	sd	s0,48(sp)
    8000255c:	f426                	sd	s1,40(sp)
    8000255e:	f04a                	sd	s2,32(sp)
    80002560:	ec4e                	sd	s3,24(sp)
    80002562:	e852                	sd	s4,16(sp)
    80002564:	e456                	sd	s5,8(sp)
    80002566:	0080                	addi	s0,sp,64
    80002568:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000256a:	0022f497          	auipc	s1,0x22f
    8000256e:	a2e48493          	addi	s1,s1,-1490 # 80230f98 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002572:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002574:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002576:	00235917          	auipc	s2,0x235
    8000257a:	02290913          	addi	s2,s2,34 # 80237598 <tickslock>
    8000257e:	a811                	j	80002592 <wakeup+0x3c>
      }
      release(&p->lock);
    80002580:	8526                	mv	a0,s1
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	76e080e7          	jalr	1902(ra) # 80000cf0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000258a:	19848493          	addi	s1,s1,408
    8000258e:	03248663          	beq	s1,s2,800025ba <wakeup+0x64>
    if (p != myproc())
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	53a080e7          	jalr	1338(ra) # 80001acc <myproc>
    8000259a:	fea488e3          	beq	s1,a0,8000258a <wakeup+0x34>
      acquire(&p->lock);
    8000259e:	8526                	mv	a0,s1
    800025a0:	ffffe097          	auipc	ra,0xffffe
    800025a4:	69c080e7          	jalr	1692(ra) # 80000c3c <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800025a8:	4c9c                	lw	a5,24(s1)
    800025aa:	fd379be3          	bne	a5,s3,80002580 <wakeup+0x2a>
    800025ae:	709c                	ld	a5,32(s1)
    800025b0:	fd4798e3          	bne	a5,s4,80002580 <wakeup+0x2a>
        p->state = RUNNABLE;
    800025b4:	0154ac23          	sw	s5,24(s1)
    800025b8:	b7e1                	j	80002580 <wakeup+0x2a>
    }
  }
}
    800025ba:	70e2                	ld	ra,56(sp)
    800025bc:	7442                	ld	s0,48(sp)
    800025be:	74a2                	ld	s1,40(sp)
    800025c0:	7902                	ld	s2,32(sp)
    800025c2:	69e2                	ld	s3,24(sp)
    800025c4:	6a42                	ld	s4,16(sp)
    800025c6:	6aa2                	ld	s5,8(sp)
    800025c8:	6121                	addi	sp,sp,64
    800025ca:	8082                	ret

00000000800025cc <reparent>:
{
    800025cc:	7179                	addi	sp,sp,-48
    800025ce:	f406                	sd	ra,40(sp)
    800025d0:	f022                	sd	s0,32(sp)
    800025d2:	ec26                	sd	s1,24(sp)
    800025d4:	e84a                	sd	s2,16(sp)
    800025d6:	e44e                	sd	s3,8(sp)
    800025d8:	e052                	sd	s4,0(sp)
    800025da:	1800                	addi	s0,sp,48
    800025dc:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800025de:	0022f497          	auipc	s1,0x22f
    800025e2:	9ba48493          	addi	s1,s1,-1606 # 80230f98 <proc>
      pp->parent = initproc;
    800025e6:	00006a17          	auipc	s4,0x6
    800025ea:	2f2a0a13          	addi	s4,s4,754 # 800088d8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800025ee:	00235997          	auipc	s3,0x235
    800025f2:	faa98993          	addi	s3,s3,-86 # 80237598 <tickslock>
    800025f6:	a029                	j	80002600 <reparent+0x34>
    800025f8:	19848493          	addi	s1,s1,408
    800025fc:	01348d63          	beq	s1,s3,80002616 <reparent+0x4a>
    if (pp->parent == p)
    80002600:	7c9c                	ld	a5,56(s1)
    80002602:	ff279be3          	bne	a5,s2,800025f8 <reparent+0x2c>
      pp->parent = initproc;
    80002606:	000a3503          	ld	a0,0(s4)
    8000260a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000260c:	00000097          	auipc	ra,0x0
    80002610:	f4a080e7          	jalr	-182(ra) # 80002556 <wakeup>
    80002614:	b7d5                	j	800025f8 <reparent+0x2c>
}
    80002616:	70a2                	ld	ra,40(sp)
    80002618:	7402                	ld	s0,32(sp)
    8000261a:	64e2                	ld	s1,24(sp)
    8000261c:	6942                	ld	s2,16(sp)
    8000261e:	69a2                	ld	s3,8(sp)
    80002620:	6a02                	ld	s4,0(sp)
    80002622:	6145                	addi	sp,sp,48
    80002624:	8082                	ret

0000000080002626 <exit>:
{
    80002626:	7179                	addi	sp,sp,-48
    80002628:	f406                	sd	ra,40(sp)
    8000262a:	f022                	sd	s0,32(sp)
    8000262c:	ec26                	sd	s1,24(sp)
    8000262e:	e84a                	sd	s2,16(sp)
    80002630:	e44e                	sd	s3,8(sp)
    80002632:	e052                	sd	s4,0(sp)
    80002634:	1800                	addi	s0,sp,48
    80002636:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002638:	fffff097          	auipc	ra,0xfffff
    8000263c:	494080e7          	jalr	1172(ra) # 80001acc <myproc>
    80002640:	89aa                	mv	s3,a0
  if (p == initproc)
    80002642:	00006797          	auipc	a5,0x6
    80002646:	2967b783          	ld	a5,662(a5) # 800088d8 <initproc>
    8000264a:	0d050493          	addi	s1,a0,208
    8000264e:	15050913          	addi	s2,a0,336
    80002652:	02a79363          	bne	a5,a0,80002678 <exit+0x52>
    panic("init exiting");
    80002656:	00006517          	auipc	a0,0x6
    8000265a:	c0a50513          	addi	a0,a0,-1014 # 80008260 <digits+0x220>
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	ee0080e7          	jalr	-288(ra) # 8000053e <panic>
      fileclose(f);
    80002666:	00002097          	auipc	ra,0x2
    8000266a:	65e080e7          	jalr	1630(ra) # 80004cc4 <fileclose>
      p->ofile[fd] = 0;
    8000266e:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002672:	04a1                	addi	s1,s1,8
    80002674:	01248563          	beq	s1,s2,8000267e <exit+0x58>
    if (p->ofile[fd])
    80002678:	6088                	ld	a0,0(s1)
    8000267a:	f575                	bnez	a0,80002666 <exit+0x40>
    8000267c:	bfdd                	j	80002672 <exit+0x4c>
  begin_op();
    8000267e:	00002097          	auipc	ra,0x2
    80002682:	17a080e7          	jalr	378(ra) # 800047f8 <begin_op>
  iput(p->cwd);
    80002686:	1509b503          	ld	a0,336(s3)
    8000268a:	00002097          	auipc	ra,0x2
    8000268e:	966080e7          	jalr	-1690(ra) # 80003ff0 <iput>
  end_op();
    80002692:	00002097          	auipc	ra,0x2
    80002696:	1e6080e7          	jalr	486(ra) # 80004878 <end_op>
  p->cwd = 0;
    8000269a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000269e:	0022e497          	auipc	s1,0x22e
    800026a2:	4e248493          	addi	s1,s1,1250 # 80230b80 <wait_lock>
    800026a6:	8526                	mv	a0,s1
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	594080e7          	jalr	1428(ra) # 80000c3c <acquire>
  reparent(p);
    800026b0:	854e                	mv	a0,s3
    800026b2:	00000097          	auipc	ra,0x0
    800026b6:	f1a080e7          	jalr	-230(ra) # 800025cc <reparent>
  wakeup(p->parent);
    800026ba:	0389b503          	ld	a0,56(s3)
    800026be:	00000097          	auipc	ra,0x0
    800026c2:	e98080e7          	jalr	-360(ra) # 80002556 <wakeup>
  acquire(&p->lock);
    800026c6:	854e                	mv	a0,s3
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	574080e7          	jalr	1396(ra) # 80000c3c <acquire>
  p->xstate = status;
    800026d0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800026d4:	4795                	li	a5,5
    800026d6:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800026da:	00006797          	auipc	a5,0x6
    800026de:	2067a783          	lw	a5,518(a5) # 800088e0 <ticks>
    800026e2:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800026e6:	8526                	mv	a0,s1
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	608080e7          	jalr	1544(ra) # 80000cf0 <release>
  sched();
    800026f0:	00000097          	auipc	ra,0x0
    800026f4:	cf0080e7          	jalr	-784(ra) # 800023e0 <sched>
  panic("zombie exit");
    800026f8:	00006517          	auipc	a0,0x6
    800026fc:	b7850513          	addi	a0,a0,-1160 # 80008270 <digits+0x230>
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	e3e080e7          	jalr	-450(ra) # 8000053e <panic>

0000000080002708 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002708:	7179                	addi	sp,sp,-48
    8000270a:	f406                	sd	ra,40(sp)
    8000270c:	f022                	sd	s0,32(sp)
    8000270e:	ec26                	sd	s1,24(sp)
    80002710:	e84a                	sd	s2,16(sp)
    80002712:	e44e                	sd	s3,8(sp)
    80002714:	1800                	addi	s0,sp,48
    80002716:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002718:	0022f497          	auipc	s1,0x22f
    8000271c:	88048493          	addi	s1,s1,-1920 # 80230f98 <proc>
    80002720:	00235997          	auipc	s3,0x235
    80002724:	e7898993          	addi	s3,s3,-392 # 80237598 <tickslock>
  {
    acquire(&p->lock);
    80002728:	8526                	mv	a0,s1
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	512080e7          	jalr	1298(ra) # 80000c3c <acquire>
    if (p->pid == pid)
    80002732:	589c                	lw	a5,48(s1)
    80002734:	01278d63          	beq	a5,s2,8000274e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002738:	8526                	mv	a0,s1
    8000273a:	ffffe097          	auipc	ra,0xffffe
    8000273e:	5b6080e7          	jalr	1462(ra) # 80000cf0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002742:	19848493          	addi	s1,s1,408
    80002746:	ff3491e3          	bne	s1,s3,80002728 <kill+0x20>
  }
  return -1;
    8000274a:	557d                	li	a0,-1
    8000274c:	a829                	j	80002766 <kill+0x5e>
      p->killed = 1;
    8000274e:	4785                	li	a5,1
    80002750:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002752:	4c98                	lw	a4,24(s1)
    80002754:	4789                	li	a5,2
    80002756:	00f70f63          	beq	a4,a5,80002774 <kill+0x6c>
      release(&p->lock);
    8000275a:	8526                	mv	a0,s1
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	594080e7          	jalr	1428(ra) # 80000cf0 <release>
      return 0;
    80002764:	4501                	li	a0,0
}
    80002766:	70a2                	ld	ra,40(sp)
    80002768:	7402                	ld	s0,32(sp)
    8000276a:	64e2                	ld	s1,24(sp)
    8000276c:	6942                	ld	s2,16(sp)
    8000276e:	69a2                	ld	s3,8(sp)
    80002770:	6145                	addi	sp,sp,48
    80002772:	8082                	ret
        p->state = RUNNABLE;
    80002774:	478d                	li	a5,3
    80002776:	cc9c                	sw	a5,24(s1)
    80002778:	b7cd                	j	8000275a <kill+0x52>

000000008000277a <setkilled>:

void setkilled(struct proc *p)
{
    8000277a:	1101                	addi	sp,sp,-32
    8000277c:	ec06                	sd	ra,24(sp)
    8000277e:	e822                	sd	s0,16(sp)
    80002780:	e426                	sd	s1,8(sp)
    80002782:	1000                	addi	s0,sp,32
    80002784:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	4b6080e7          	jalr	1206(ra) # 80000c3c <acquire>
  p->killed = 1;
    8000278e:	4785                	li	a5,1
    80002790:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002792:	8526                	mv	a0,s1
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	55c080e7          	jalr	1372(ra) # 80000cf0 <release>
}
    8000279c:	60e2                	ld	ra,24(sp)
    8000279e:	6442                	ld	s0,16(sp)
    800027a0:	64a2                	ld	s1,8(sp)
    800027a2:	6105                	addi	sp,sp,32
    800027a4:	8082                	ret

00000000800027a6 <killed>:

int killed(struct proc *p)
{
    800027a6:	1101                	addi	sp,sp,-32
    800027a8:	ec06                	sd	ra,24(sp)
    800027aa:	e822                	sd	s0,16(sp)
    800027ac:	e426                	sd	s1,8(sp)
    800027ae:	e04a                	sd	s2,0(sp)
    800027b0:	1000                	addi	s0,sp,32
    800027b2:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	488080e7          	jalr	1160(ra) # 80000c3c <acquire>
  k = p->killed;
    800027bc:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800027c0:	8526                	mv	a0,s1
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	52e080e7          	jalr	1326(ra) # 80000cf0 <release>
  return k;
}
    800027ca:	854a                	mv	a0,s2
    800027cc:	60e2                	ld	ra,24(sp)
    800027ce:	6442                	ld	s0,16(sp)
    800027d0:	64a2                	ld	s1,8(sp)
    800027d2:	6902                	ld	s2,0(sp)
    800027d4:	6105                	addi	sp,sp,32
    800027d6:	8082                	ret

00000000800027d8 <wait>:
{
    800027d8:	715d                	addi	sp,sp,-80
    800027da:	e486                	sd	ra,72(sp)
    800027dc:	e0a2                	sd	s0,64(sp)
    800027de:	fc26                	sd	s1,56(sp)
    800027e0:	f84a                	sd	s2,48(sp)
    800027e2:	f44e                	sd	s3,40(sp)
    800027e4:	f052                	sd	s4,32(sp)
    800027e6:	ec56                	sd	s5,24(sp)
    800027e8:	e85a                	sd	s6,16(sp)
    800027ea:	e45e                	sd	s7,8(sp)
    800027ec:	e062                	sd	s8,0(sp)
    800027ee:	0880                	addi	s0,sp,80
    800027f0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800027f2:	fffff097          	auipc	ra,0xfffff
    800027f6:	2da080e7          	jalr	730(ra) # 80001acc <myproc>
    800027fa:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800027fc:	0022e517          	auipc	a0,0x22e
    80002800:	38450513          	addi	a0,a0,900 # 80230b80 <wait_lock>
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	438080e7          	jalr	1080(ra) # 80000c3c <acquire>
    havekids = 0;
    8000280c:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000280e:	4a15                	li	s4,5
        havekids = 1;
    80002810:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002812:	00235997          	auipc	s3,0x235
    80002816:	d8698993          	addi	s3,s3,-634 # 80237598 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000281a:	0022ec17          	auipc	s8,0x22e
    8000281e:	366c0c13          	addi	s8,s8,870 # 80230b80 <wait_lock>
    havekids = 0;
    80002822:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002824:	0022e497          	auipc	s1,0x22e
    80002828:	77448493          	addi	s1,s1,1908 # 80230f98 <proc>
    8000282c:	a0bd                	j	8000289a <wait+0xc2>
          pid = pp->pid;
    8000282e:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002832:	000b0e63          	beqz	s6,8000284e <wait+0x76>
    80002836:	4691                	li	a3,4
    80002838:	02c48613          	addi	a2,s1,44
    8000283c:	85da                	mv	a1,s6
    8000283e:	05093503          	ld	a0,80(s2)
    80002842:	fffff097          	auipc	ra,0xfffff
    80002846:	eb2080e7          	jalr	-334(ra) # 800016f4 <copyout>
    8000284a:	02054563          	bltz	a0,80002874 <wait+0x9c>
          freeproc(pp);
    8000284e:	8526                	mv	a0,s1
    80002850:	fffff097          	auipc	ra,0xfffff
    80002854:	42e080e7          	jalr	1070(ra) # 80001c7e <freeproc>
          release(&pp->lock);
    80002858:	8526                	mv	a0,s1
    8000285a:	ffffe097          	auipc	ra,0xffffe
    8000285e:	496080e7          	jalr	1174(ra) # 80000cf0 <release>
          release(&wait_lock);
    80002862:	0022e517          	auipc	a0,0x22e
    80002866:	31e50513          	addi	a0,a0,798 # 80230b80 <wait_lock>
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	486080e7          	jalr	1158(ra) # 80000cf0 <release>
          return pid;
    80002872:	a0b5                	j	800028de <wait+0x106>
            release(&pp->lock);
    80002874:	8526                	mv	a0,s1
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	47a080e7          	jalr	1146(ra) # 80000cf0 <release>
            release(&wait_lock);
    8000287e:	0022e517          	auipc	a0,0x22e
    80002882:	30250513          	addi	a0,a0,770 # 80230b80 <wait_lock>
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	46a080e7          	jalr	1130(ra) # 80000cf0 <release>
            return -1;
    8000288e:	59fd                	li	s3,-1
    80002890:	a0b9                	j	800028de <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002892:	19848493          	addi	s1,s1,408
    80002896:	03348463          	beq	s1,s3,800028be <wait+0xe6>
      if (pp->parent == p)
    8000289a:	7c9c                	ld	a5,56(s1)
    8000289c:	ff279be3          	bne	a5,s2,80002892 <wait+0xba>
        acquire(&pp->lock);
    800028a0:	8526                	mv	a0,s1
    800028a2:	ffffe097          	auipc	ra,0xffffe
    800028a6:	39a080e7          	jalr	922(ra) # 80000c3c <acquire>
        if (pp->state == ZOMBIE)
    800028aa:	4c9c                	lw	a5,24(s1)
    800028ac:	f94781e3          	beq	a5,s4,8000282e <wait+0x56>
        release(&pp->lock);
    800028b0:	8526                	mv	a0,s1
    800028b2:	ffffe097          	auipc	ra,0xffffe
    800028b6:	43e080e7          	jalr	1086(ra) # 80000cf0 <release>
        havekids = 1;
    800028ba:	8756                	mv	a4,s5
    800028bc:	bfd9                	j	80002892 <wait+0xba>
    if (!havekids || killed(p))
    800028be:	c719                	beqz	a4,800028cc <wait+0xf4>
    800028c0:	854a                	mv	a0,s2
    800028c2:	00000097          	auipc	ra,0x0
    800028c6:	ee4080e7          	jalr	-284(ra) # 800027a6 <killed>
    800028ca:	c51d                	beqz	a0,800028f8 <wait+0x120>
      release(&wait_lock);
    800028cc:	0022e517          	auipc	a0,0x22e
    800028d0:	2b450513          	addi	a0,a0,692 # 80230b80 <wait_lock>
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	41c080e7          	jalr	1052(ra) # 80000cf0 <release>
      return -1;
    800028dc:	59fd                	li	s3,-1
}
    800028de:	854e                	mv	a0,s3
    800028e0:	60a6                	ld	ra,72(sp)
    800028e2:	6406                	ld	s0,64(sp)
    800028e4:	74e2                	ld	s1,56(sp)
    800028e6:	7942                	ld	s2,48(sp)
    800028e8:	79a2                	ld	s3,40(sp)
    800028ea:	7a02                	ld	s4,32(sp)
    800028ec:	6ae2                	ld	s5,24(sp)
    800028ee:	6b42                	ld	s6,16(sp)
    800028f0:	6ba2                	ld	s7,8(sp)
    800028f2:	6c02                	ld	s8,0(sp)
    800028f4:	6161                	addi	sp,sp,80
    800028f6:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800028f8:	85e2                	mv	a1,s8
    800028fa:	854a                	mv	a0,s2
    800028fc:	00000097          	auipc	ra,0x0
    80002900:	bf6080e7          	jalr	-1034(ra) # 800024f2 <sleep>
    havekids = 0;
    80002904:	bf39                	j	80002822 <wait+0x4a>

0000000080002906 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002906:	7179                	addi	sp,sp,-48
    80002908:	f406                	sd	ra,40(sp)
    8000290a:	f022                	sd	s0,32(sp)
    8000290c:	ec26                	sd	s1,24(sp)
    8000290e:	e84a                	sd	s2,16(sp)
    80002910:	e44e                	sd	s3,8(sp)
    80002912:	e052                	sd	s4,0(sp)
    80002914:	1800                	addi	s0,sp,48
    80002916:	84aa                	mv	s1,a0
    80002918:	892e                	mv	s2,a1
    8000291a:	89b2                	mv	s3,a2
    8000291c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000291e:	fffff097          	auipc	ra,0xfffff
    80002922:	1ae080e7          	jalr	430(ra) # 80001acc <myproc>
  if (user_dst)
    80002926:	c08d                	beqz	s1,80002948 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002928:	86d2                	mv	a3,s4
    8000292a:	864e                	mv	a2,s3
    8000292c:	85ca                	mv	a1,s2
    8000292e:	6928                	ld	a0,80(a0)
    80002930:	fffff097          	auipc	ra,0xfffff
    80002934:	dc4080e7          	jalr	-572(ra) # 800016f4 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002938:	70a2                	ld	ra,40(sp)
    8000293a:	7402                	ld	s0,32(sp)
    8000293c:	64e2                	ld	s1,24(sp)
    8000293e:	6942                	ld	s2,16(sp)
    80002940:	69a2                	ld	s3,8(sp)
    80002942:	6a02                	ld	s4,0(sp)
    80002944:	6145                	addi	sp,sp,48
    80002946:	8082                	ret
    memmove((char *)dst, src, len);
    80002948:	000a061b          	sext.w	a2,s4
    8000294c:	85ce                	mv	a1,s3
    8000294e:	854a                	mv	a0,s2
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	444080e7          	jalr	1092(ra) # 80000d94 <memmove>
    return 0;
    80002958:	8526                	mv	a0,s1
    8000295a:	bff9                	j	80002938 <either_copyout+0x32>

000000008000295c <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000295c:	7179                	addi	sp,sp,-48
    8000295e:	f406                	sd	ra,40(sp)
    80002960:	f022                	sd	s0,32(sp)
    80002962:	ec26                	sd	s1,24(sp)
    80002964:	e84a                	sd	s2,16(sp)
    80002966:	e44e                	sd	s3,8(sp)
    80002968:	e052                	sd	s4,0(sp)
    8000296a:	1800                	addi	s0,sp,48
    8000296c:	892a                	mv	s2,a0
    8000296e:	84ae                	mv	s1,a1
    80002970:	89b2                	mv	s3,a2
    80002972:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002974:	fffff097          	auipc	ra,0xfffff
    80002978:	158080e7          	jalr	344(ra) # 80001acc <myproc>
  if (user_src)
    8000297c:	c08d                	beqz	s1,8000299e <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000297e:	86d2                	mv	a3,s4
    80002980:	864e                	mv	a2,s3
    80002982:	85ca                	mv	a1,s2
    80002984:	6928                	ld	a0,80(a0)
    80002986:	fffff097          	auipc	ra,0xfffff
    8000298a:	e8e080e7          	jalr	-370(ra) # 80001814 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000298e:	70a2                	ld	ra,40(sp)
    80002990:	7402                	ld	s0,32(sp)
    80002992:	64e2                	ld	s1,24(sp)
    80002994:	6942                	ld	s2,16(sp)
    80002996:	69a2                	ld	s3,8(sp)
    80002998:	6a02                	ld	s4,0(sp)
    8000299a:	6145                	addi	sp,sp,48
    8000299c:	8082                	ret
    memmove(dst, (char *)src, len);
    8000299e:	000a061b          	sext.w	a2,s4
    800029a2:	85ce                	mv	a1,s3
    800029a4:	854a                	mv	a0,s2
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	3ee080e7          	jalr	1006(ra) # 80000d94 <memmove>
    return 0;
    800029ae:	8526                	mv	a0,s1
    800029b0:	bff9                	j	8000298e <either_copyin+0x32>

00000000800029b2 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800029b2:	715d                	addi	sp,sp,-80
    800029b4:	e486                	sd	ra,72(sp)
    800029b6:	e0a2                	sd	s0,64(sp)
    800029b8:	fc26                	sd	s1,56(sp)
    800029ba:	f84a                	sd	s2,48(sp)
    800029bc:	f44e                	sd	s3,40(sp)
    800029be:	f052                	sd	s4,32(sp)
    800029c0:	ec56                	sd	s5,24(sp)
    800029c2:	e85a                	sd	s6,16(sp)
    800029c4:	e45e                	sd	s7,8(sp)
    800029c6:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800029c8:	00005517          	auipc	a0,0x5
    800029cc:	70050513          	addi	a0,a0,1792 # 800080c8 <digits+0x88>
    800029d0:	ffffe097          	auipc	ra,0xffffe
    800029d4:	bb8080e7          	jalr	-1096(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800029d8:	0022e497          	auipc	s1,0x22e
    800029dc:	71848493          	addi	s1,s1,1816 # 802310f0 <proc+0x158>
    800029e0:	00235917          	auipc	s2,0x235
    800029e4:	d1090913          	addi	s2,s2,-752 # 802376f0 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029e8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800029ea:	00006997          	auipc	s3,0x6
    800029ee:	89698993          	addi	s3,s3,-1898 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800029f2:	00006a97          	auipc	s5,0x6
    800029f6:	896a8a93          	addi	s5,s5,-1898 # 80008288 <digits+0x248>
    printf("\n");
    800029fa:	00005a17          	auipc	s4,0x5
    800029fe:	6cea0a13          	addi	s4,s4,1742 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a02:	00006b97          	auipc	s7,0x6
    80002a06:	8c6b8b93          	addi	s7,s7,-1850 # 800082c8 <states.0>
    80002a0a:	a00d                	j	80002a2c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002a0c:	ed86a583          	lw	a1,-296(a3)
    80002a10:	8556                	mv	a0,s5
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	b76080e7          	jalr	-1162(ra) # 80000588 <printf>
    printf("\n");
    80002a1a:	8552                	mv	a0,s4
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	b6c080e7          	jalr	-1172(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002a24:	19848493          	addi	s1,s1,408
    80002a28:	03248163          	beq	s1,s2,80002a4a <procdump+0x98>
    if (p->state == UNUSED)
    80002a2c:	86a6                	mv	a3,s1
    80002a2e:	ec04a783          	lw	a5,-320(s1)
    80002a32:	dbed                	beqz	a5,80002a24 <procdump+0x72>
      state = "???";
    80002a34:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a36:	fcfb6be3          	bltu	s6,a5,80002a0c <procdump+0x5a>
    80002a3a:	1782                	slli	a5,a5,0x20
    80002a3c:	9381                	srli	a5,a5,0x20
    80002a3e:	078e                	slli	a5,a5,0x3
    80002a40:	97de                	add	a5,a5,s7
    80002a42:	6390                	ld	a2,0(a5)
    80002a44:	f661                	bnez	a2,80002a0c <procdump+0x5a>
      state = "???";
    80002a46:	864e                	mv	a2,s3
    80002a48:	b7d1                	j	80002a0c <procdump+0x5a>
  }
}
    80002a4a:	60a6                	ld	ra,72(sp)
    80002a4c:	6406                	ld	s0,64(sp)
    80002a4e:	74e2                	ld	s1,56(sp)
    80002a50:	7942                	ld	s2,48(sp)
    80002a52:	79a2                	ld	s3,40(sp)
    80002a54:	7a02                	ld	s4,32(sp)
    80002a56:	6ae2                	ld	s5,24(sp)
    80002a58:	6b42                	ld	s6,16(sp)
    80002a5a:	6ba2                	ld	s7,8(sp)
    80002a5c:	6161                	addi	sp,sp,80
    80002a5e:	8082                	ret

0000000080002a60 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002a60:	711d                	addi	sp,sp,-96
    80002a62:	ec86                	sd	ra,88(sp)
    80002a64:	e8a2                	sd	s0,80(sp)
    80002a66:	e4a6                	sd	s1,72(sp)
    80002a68:	e0ca                	sd	s2,64(sp)
    80002a6a:	fc4e                	sd	s3,56(sp)
    80002a6c:	f852                	sd	s4,48(sp)
    80002a6e:	f456                	sd	s5,40(sp)
    80002a70:	f05a                	sd	s6,32(sp)
    80002a72:	ec5e                	sd	s7,24(sp)
    80002a74:	e862                	sd	s8,16(sp)
    80002a76:	e466                	sd	s9,8(sp)
    80002a78:	e06a                	sd	s10,0(sp)
    80002a7a:	1080                	addi	s0,sp,96
    80002a7c:	8b2a                	mv	s6,a0
    80002a7e:	8bae                	mv	s7,a1
    80002a80:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002a82:	fffff097          	auipc	ra,0xfffff
    80002a86:	04a080e7          	jalr	74(ra) # 80001acc <myproc>
    80002a8a:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002a8c:	0022e517          	auipc	a0,0x22e
    80002a90:	0f450513          	addi	a0,a0,244 # 80230b80 <wait_lock>
    80002a94:	ffffe097          	auipc	ra,0xffffe
    80002a98:	1a8080e7          	jalr	424(ra) # 80000c3c <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002a9c:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002a9e:	4a15                	li	s4,5
        havekids = 1;
    80002aa0:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002aa2:	00235997          	auipc	s3,0x235
    80002aa6:	af698993          	addi	s3,s3,-1290 # 80237598 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002aaa:	0022ed17          	auipc	s10,0x22e
    80002aae:	0d6d0d13          	addi	s10,s10,214 # 80230b80 <wait_lock>
    havekids = 0;
    80002ab2:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002ab4:	0022e497          	auipc	s1,0x22e
    80002ab8:	4e448493          	addi	s1,s1,1252 # 80230f98 <proc>
    80002abc:	a059                	j	80002b42 <waitx+0xe2>
          pid = np->pid;
    80002abe:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002ac2:	1684a703          	lw	a4,360(s1)
    80002ac6:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002aca:	16c4a783          	lw	a5,364(s1)
    80002ace:	9f3d                	addw	a4,a4,a5
    80002ad0:	1704a783          	lw	a5,368(s1)
    80002ad4:	9f99                	subw	a5,a5,a4
    80002ad6:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002ada:	000b0e63          	beqz	s6,80002af6 <waitx+0x96>
    80002ade:	4691                	li	a3,4
    80002ae0:	02c48613          	addi	a2,s1,44
    80002ae4:	85da                	mv	a1,s6
    80002ae6:	05093503          	ld	a0,80(s2)
    80002aea:	fffff097          	auipc	ra,0xfffff
    80002aee:	c0a080e7          	jalr	-1014(ra) # 800016f4 <copyout>
    80002af2:	02054563          	bltz	a0,80002b1c <waitx+0xbc>
          freeproc(np);
    80002af6:	8526                	mv	a0,s1
    80002af8:	fffff097          	auipc	ra,0xfffff
    80002afc:	186080e7          	jalr	390(ra) # 80001c7e <freeproc>
          release(&np->lock);
    80002b00:	8526                	mv	a0,s1
    80002b02:	ffffe097          	auipc	ra,0xffffe
    80002b06:	1ee080e7          	jalr	494(ra) # 80000cf0 <release>
          release(&wait_lock);
    80002b0a:	0022e517          	auipc	a0,0x22e
    80002b0e:	07650513          	addi	a0,a0,118 # 80230b80 <wait_lock>
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	1de080e7          	jalr	478(ra) # 80000cf0 <release>
          return pid;
    80002b1a:	a09d                	j	80002b80 <waitx+0x120>
            release(&np->lock);
    80002b1c:	8526                	mv	a0,s1
    80002b1e:	ffffe097          	auipc	ra,0xffffe
    80002b22:	1d2080e7          	jalr	466(ra) # 80000cf0 <release>
            release(&wait_lock);
    80002b26:	0022e517          	auipc	a0,0x22e
    80002b2a:	05a50513          	addi	a0,a0,90 # 80230b80 <wait_lock>
    80002b2e:	ffffe097          	auipc	ra,0xffffe
    80002b32:	1c2080e7          	jalr	450(ra) # 80000cf0 <release>
            return -1;
    80002b36:	59fd                	li	s3,-1
    80002b38:	a0a1                	j	80002b80 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002b3a:	19848493          	addi	s1,s1,408
    80002b3e:	03348463          	beq	s1,s3,80002b66 <waitx+0x106>
      if (np->parent == p)
    80002b42:	7c9c                	ld	a5,56(s1)
    80002b44:	ff279be3          	bne	a5,s2,80002b3a <waitx+0xda>
        acquire(&np->lock);
    80002b48:	8526                	mv	a0,s1
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	0f2080e7          	jalr	242(ra) # 80000c3c <acquire>
        if (np->state == ZOMBIE)
    80002b52:	4c9c                	lw	a5,24(s1)
    80002b54:	f74785e3          	beq	a5,s4,80002abe <waitx+0x5e>
        release(&np->lock);
    80002b58:	8526                	mv	a0,s1
    80002b5a:	ffffe097          	auipc	ra,0xffffe
    80002b5e:	196080e7          	jalr	406(ra) # 80000cf0 <release>
        havekids = 1;
    80002b62:	8756                	mv	a4,s5
    80002b64:	bfd9                	j	80002b3a <waitx+0xda>
    if (!havekids || p->killed)
    80002b66:	c701                	beqz	a4,80002b6e <waitx+0x10e>
    80002b68:	02892783          	lw	a5,40(s2)
    80002b6c:	cb8d                	beqz	a5,80002b9e <waitx+0x13e>
      release(&wait_lock);
    80002b6e:	0022e517          	auipc	a0,0x22e
    80002b72:	01250513          	addi	a0,a0,18 # 80230b80 <wait_lock>
    80002b76:	ffffe097          	auipc	ra,0xffffe
    80002b7a:	17a080e7          	jalr	378(ra) # 80000cf0 <release>
      return -1;
    80002b7e:	59fd                	li	s3,-1
  }
}
    80002b80:	854e                	mv	a0,s3
    80002b82:	60e6                	ld	ra,88(sp)
    80002b84:	6446                	ld	s0,80(sp)
    80002b86:	64a6                	ld	s1,72(sp)
    80002b88:	6906                	ld	s2,64(sp)
    80002b8a:	79e2                	ld	s3,56(sp)
    80002b8c:	7a42                	ld	s4,48(sp)
    80002b8e:	7aa2                	ld	s5,40(sp)
    80002b90:	7b02                	ld	s6,32(sp)
    80002b92:	6be2                	ld	s7,24(sp)
    80002b94:	6c42                	ld	s8,16(sp)
    80002b96:	6ca2                	ld	s9,8(sp)
    80002b98:	6d02                	ld	s10,0(sp)
    80002b9a:	6125                	addi	sp,sp,96
    80002b9c:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002b9e:	85ea                	mv	a1,s10
    80002ba0:	854a                	mv	a0,s2
    80002ba2:	00000097          	auipc	ra,0x0
    80002ba6:	950080e7          	jalr	-1712(ra) # 800024f2 <sleep>
    havekids = 0;
    80002baa:	b721                	j	80002ab2 <waitx+0x52>

0000000080002bac <update_time>:

void update_time()
{
    80002bac:	7139                	addi	sp,sp,-64
    80002bae:	fc06                	sd	ra,56(sp)
    80002bb0:	f822                	sd	s0,48(sp)
    80002bb2:	f426                	sd	s1,40(sp)
    80002bb4:	f04a                	sd	s2,32(sp)
    80002bb6:	ec4e                	sd	s3,24(sp)
    80002bb8:	e852                	sd	s4,16(sp)
    80002bba:	e456                	sd	s5,8(sp)
    80002bbc:	0080                	addi	s0,sp,64
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002bbe:	0022e497          	auipc	s1,0x22e
    80002bc2:	3da48493          	addi	s1,s1,986 # 80230f98 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002bc6:	4991                	li	s3,4
    {
      p->rtime++;
      p->runtime++;
    }
    else if (p->state == SLEEPING)
    80002bc8:	4a09                	li	s4,2
      p->stime++;
    else if (p->state == RUNNABLE)
    80002bca:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002bcc:	00235917          	auipc	s2,0x235
    80002bd0:	9cc90913          	addi	s2,s2,-1588 # 80237598 <tickslock>
    80002bd4:	a025                	j	80002bfc <update_time+0x50>
      p->rtime++;
    80002bd6:	1684a783          	lw	a5,360(s1)
    80002bda:	2785                	addiw	a5,a5,1
    80002bdc:	16f4a423          	sw	a5,360(s1)
      p->runtime++;
    80002be0:	1804a783          	lw	a5,384(s1)
    80002be4:	2785                	addiw	a5,a5,1
    80002be6:	18f4a023          	sw	a5,384(s1)
      p->wtime++;
    // printf("%d %d %d %d\n",p->pid,p->wtime,p->rtime,p->stime);
    release(&p->lock);
    80002bea:	8526                	mv	a0,s1
    80002bec:	ffffe097          	auipc	ra,0xffffe
    80002bf0:	104080e7          	jalr	260(ra) # 80000cf0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002bf4:	19848493          	addi	s1,s1,408
    80002bf8:	03248a63          	beq	s1,s2,80002c2c <update_time+0x80>
    acquire(&p->lock);
    80002bfc:	8526                	mv	a0,s1
    80002bfe:	ffffe097          	auipc	ra,0xffffe
    80002c02:	03e080e7          	jalr	62(ra) # 80000c3c <acquire>
    if (p->state == RUNNING)
    80002c06:	4c9c                	lw	a5,24(s1)
    80002c08:	fd3787e3          	beq	a5,s3,80002bd6 <update_time+0x2a>
    else if (p->state == SLEEPING)
    80002c0c:	01478a63          	beq	a5,s4,80002c20 <update_time+0x74>
    else if (p->state == RUNNABLE)
    80002c10:	fd579de3          	bne	a5,s5,80002bea <update_time+0x3e>
      p->wtime++;
    80002c14:	1884a783          	lw	a5,392(s1)
    80002c18:	2785                	addiw	a5,a5,1
    80002c1a:	18f4a423          	sw	a5,392(s1)
    80002c1e:	b7f1                	j	80002bea <update_time+0x3e>
      p->stime++;
    80002c20:	1844a783          	lw	a5,388(s1)
    80002c24:	2785                	addiw	a5,a5,1
    80002c26:	18f4a223          	sw	a5,388(s1)
    80002c2a:	b7c1                	j	80002bea <update_time+0x3e>
  }
    80002c2c:	70e2                	ld	ra,56(sp)
    80002c2e:	7442                	ld	s0,48(sp)
    80002c30:	74a2                	ld	s1,40(sp)
    80002c32:	7902                	ld	s2,32(sp)
    80002c34:	69e2                	ld	s3,24(sp)
    80002c36:	6a42                	ld	s4,16(sp)
    80002c38:	6aa2                	ld	s5,8(sp)
    80002c3a:	6121                	addi	sp,sp,64
    80002c3c:	8082                	ret

0000000080002c3e <swtch>:
    80002c3e:	00153023          	sd	ra,0(a0)
    80002c42:	00253423          	sd	sp,8(a0)
    80002c46:	e900                	sd	s0,16(a0)
    80002c48:	ed04                	sd	s1,24(a0)
    80002c4a:	03253023          	sd	s2,32(a0)
    80002c4e:	03353423          	sd	s3,40(a0)
    80002c52:	03453823          	sd	s4,48(a0)
    80002c56:	03553c23          	sd	s5,56(a0)
    80002c5a:	05653023          	sd	s6,64(a0)
    80002c5e:	05753423          	sd	s7,72(a0)
    80002c62:	05853823          	sd	s8,80(a0)
    80002c66:	05953c23          	sd	s9,88(a0)
    80002c6a:	07a53023          	sd	s10,96(a0)
    80002c6e:	07b53423          	sd	s11,104(a0)
    80002c72:	0005b083          	ld	ra,0(a1)
    80002c76:	0085b103          	ld	sp,8(a1)
    80002c7a:	6980                	ld	s0,16(a1)
    80002c7c:	6d84                	ld	s1,24(a1)
    80002c7e:	0205b903          	ld	s2,32(a1)
    80002c82:	0285b983          	ld	s3,40(a1)
    80002c86:	0305ba03          	ld	s4,48(a1)
    80002c8a:	0385ba83          	ld	s5,56(a1)
    80002c8e:	0405bb03          	ld	s6,64(a1)
    80002c92:	0485bb83          	ld	s7,72(a1)
    80002c96:	0505bc03          	ld	s8,80(a1)
    80002c9a:	0585bc83          	ld	s9,88(a1)
    80002c9e:	0605bd03          	ld	s10,96(a1)
    80002ca2:	0685bd83          	ld	s11,104(a1)
    80002ca6:	8082                	ret

0000000080002ca8 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002ca8:	1141                	addi	sp,sp,-16
    80002caa:	e406                	sd	ra,8(sp)
    80002cac:	e022                	sd	s0,0(sp)
    80002cae:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002cb0:	00005597          	auipc	a1,0x5
    80002cb4:	64858593          	addi	a1,a1,1608 # 800082f8 <states.0+0x30>
    80002cb8:	00235517          	auipc	a0,0x235
    80002cbc:	8e050513          	addi	a0,a0,-1824 # 80237598 <tickslock>
    80002cc0:	ffffe097          	auipc	ra,0xffffe
    80002cc4:	eec080e7          	jalr	-276(ra) # 80000bac <initlock>
}
    80002cc8:	60a2                	ld	ra,8(sp)
    80002cca:	6402                	ld	s0,0(sp)
    80002ccc:	0141                	addi	sp,sp,16
    80002cce:	8082                	ret

0000000080002cd0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002cd0:	1141                	addi	sp,sp,-16
    80002cd2:	e422                	sd	s0,8(sp)
    80002cd4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cd6:	00003797          	auipc	a5,0x3
    80002cda:	73a78793          	addi	a5,a5,1850 # 80006410 <kernelvec>
    80002cde:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002ce2:	6422                	ld	s0,8(sp)
    80002ce4:	0141                	addi	sp,sp,16
    80002ce6:	8082                	ret

0000000080002ce8 <cowtest_h>:

int cowtest_h(pagetable_t pagetable, uint64 va)
{

  char *mem;
  if (va >= (1L << (9 + 9 + 9 + 12 - 1)))
    80002ce8:	57fd                	li	a5,-1
    80002cea:	83e9                	srli	a5,a5,0x1a
    80002cec:	08b7e063          	bltu	a5,a1,80002d6c <cowtest_h+0x84>
{
    80002cf0:	7179                	addi	sp,sp,-48
    80002cf2:	f406                	sd	ra,40(sp)
    80002cf4:	f022                	sd	s0,32(sp)
    80002cf6:	ec26                	sd	s1,24(sp)
    80002cf8:	e84a                	sd	s2,16(sp)
    80002cfa:	e44e                	sd	s3,8(sp)
    80002cfc:	1800                	addi	s0,sp,48
    return -1;
  pte_t *pg_tb_entry = walk(pagetable, va, 0);
    80002cfe:	4601                	li	a2,0
    80002d00:	ffffe097          	auipc	ra,0xffffe
    80002d04:	31c080e7          	jalr	796(ra) # 8000101c <walk>
    80002d08:	892a                	mv	s2,a0
  if (pg_tb_entry == 0)
    80002d0a:	c13d                	beqz	a0,80002d70 <cowtest_h+0x88>
    return -1;
  if ((*pg_tb_entry & PTE_RSW) == 0 ||(*pg_tb_entry & PTE_U) == 0 || (*pg_tb_entry & PTE_V) == 0)
    80002d0c:	611c                	ld	a5,0(a0)
    80002d0e:	1117f793          	andi	a5,a5,273
    80002d12:	11100713          	li	a4,273
    80002d16:	04e79f63          	bne	a5,a4,80002d74 <cowtest_h+0x8c>
  {
    return -1;
  }
  if ((mem = kalloc()) == 0)
    80002d1a:	ffffe097          	auipc	ra,0xffffe
    80002d1e:	e12080e7          	jalr	-494(ra) # 80000b2c <kalloc>
    80002d22:	84aa                	mv	s1,a0
    80002d24:	c931                	beqz	a0,80002d78 <cowtest_h+0x90>
  {
    return -1;
  }
  uint64 old_phys_addr = (((*pg_tb_entry) >> 10) << 12);
    80002d26:	00093983          	ld	s3,0(s2)
    80002d2a:	00a9d993          	srli	s3,s3,0xa
    80002d2e:	09b2                	slli	s3,s3,0xc
  memmove((char *)mem, (char *)old_phys_addr, 4096); // copy old data to new mem
    80002d30:	6605                	lui	a2,0x1
    80002d32:	85ce                	mv	a1,s3
    80002d34:	ffffe097          	auipc	ra,0xffffe
    80002d38:	060080e7          	jalr	96(ra) # 80000d94 <memmove>
  
  kfree((void *)old_phys_addr); // decrease refcount of old memory page, new page allocated
    80002d3c:	854e                	mv	a0,s3
    80002d3e:	ffffe097          	auipc	ra,0xffffe
    80002d42:	cac080e7          	jalr	-852(ra) # 800009ea <kfree>
  uint f = ((*pg_tb_entry) & 0x3FF);

  *pg_tb_entry = (((((uint64)mem) >> 12) << 10) | f | (1L << 2)); // set w to 1, change the address of PTE to mem
    80002d46:	80b1                	srli	s1,s1,0xc
    80002d48:	04aa                	slli	s1,s1,0xa
  uint f = ((*pg_tb_entry) & 0x3FF);
    80002d4a:	00093783          	ld	a5,0(s2)
  *pg_tb_entry = (((((uint64)mem) >> 12) << 10) | f | (1L << 2)); // set w to 1, change the address of PTE to mem
    80002d4e:	2ff7f793          	andi	a5,a5,767
  *pg_tb_entry &= ~PTE_RSW;                                       // set rsw to 0
    80002d52:	8cdd                	or	s1,s1,a5
    80002d54:	0044e493          	ori	s1,s1,4
    80002d58:	00993023          	sd	s1,0(s2)
  return 0;
    80002d5c:	4501                	li	a0,0
}
    80002d5e:	70a2                	ld	ra,40(sp)
    80002d60:	7402                	ld	s0,32(sp)
    80002d62:	64e2                	ld	s1,24(sp)
    80002d64:	6942                	ld	s2,16(sp)
    80002d66:	69a2                	ld	s3,8(sp)
    80002d68:	6145                	addi	sp,sp,48
    80002d6a:	8082                	ret
    return -1;
    80002d6c:	557d                	li	a0,-1
}
    80002d6e:	8082                	ret
    return -1;
    80002d70:	557d                	li	a0,-1
    80002d72:	b7f5                	j	80002d5e <cowtest_h+0x76>
    return -1;
    80002d74:	557d                	li	a0,-1
    80002d76:	b7e5                	j	80002d5e <cowtest_h+0x76>
    return -1;
    80002d78:	557d                	li	a0,-1
    80002d7a:	b7d5                	j	80002d5e <cowtest_h+0x76>

0000000080002d7c <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002d7c:	1141                	addi	sp,sp,-16
    80002d7e:	e406                	sd	ra,8(sp)
    80002d80:	e022                	sd	s0,0(sp)
    80002d82:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d84:	fffff097          	auipc	ra,0xfffff
    80002d88:	d48080e7          	jalr	-696(ra) # 80001acc <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d8c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d90:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d92:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002d96:	00004617          	auipc	a2,0x4
    80002d9a:	26a60613          	addi	a2,a2,618 # 80007000 <_trampoline>
    80002d9e:	00004697          	auipc	a3,0x4
    80002da2:	26268693          	addi	a3,a3,610 # 80007000 <_trampoline>
    80002da6:	8e91                	sub	a3,a3,a2
    80002da8:	040007b7          	lui	a5,0x4000
    80002dac:	17fd                	addi	a5,a5,-1
    80002dae:	07b2                	slli	a5,a5,0xc
    80002db0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002db2:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002db6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002db8:	180026f3          	csrr	a3,satp
    80002dbc:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002dbe:	6d38                	ld	a4,88(a0)
    80002dc0:	6134                	ld	a3,64(a0)
    80002dc2:	6585                	lui	a1,0x1
    80002dc4:	96ae                	add	a3,a3,a1
    80002dc6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002dc8:	6d38                	ld	a4,88(a0)
    80002dca:	00000697          	auipc	a3,0x0
    80002dce:	13e68693          	addi	a3,a3,318 # 80002f08 <usertrap>
    80002dd2:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002dd4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002dd6:	8692                	mv	a3,tp
    80002dd8:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dda:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002dde:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002de2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002de6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002dea:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002dec:	6f18                	ld	a4,24(a4)
    80002dee:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002df2:	6928                	ld	a0,80(a0)
    80002df4:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002df6:	00004717          	auipc	a4,0x4
    80002dfa:	2a670713          	addi	a4,a4,678 # 8000709c <userret>
    80002dfe:	8f11                	sub	a4,a4,a2
    80002e00:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002e02:	577d                	li	a4,-1
    80002e04:	177e                	slli	a4,a4,0x3f
    80002e06:	8d59                	or	a0,a0,a4
    80002e08:	9782                	jalr	a5
}
    80002e0a:	60a2                	ld	ra,8(sp)
    80002e0c:	6402                	ld	s0,0(sp)
    80002e0e:	0141                	addi	sp,sp,16
    80002e10:	8082                	ret

0000000080002e12 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002e12:	1101                	addi	sp,sp,-32
    80002e14:	ec06                	sd	ra,24(sp)
    80002e16:	e822                	sd	s0,16(sp)
    80002e18:	e426                	sd	s1,8(sp)
    80002e1a:	e04a                	sd	s2,0(sp)
    80002e1c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002e1e:	00234917          	auipc	s2,0x234
    80002e22:	77a90913          	addi	s2,s2,1914 # 80237598 <tickslock>
    80002e26:	854a                	mv	a0,s2
    80002e28:	ffffe097          	auipc	ra,0xffffe
    80002e2c:	e14080e7          	jalr	-492(ra) # 80000c3c <acquire>
  ticks++;
    80002e30:	00006497          	auipc	s1,0x6
    80002e34:	ab048493          	addi	s1,s1,-1360 # 800088e0 <ticks>
    80002e38:	409c                	lw	a5,0(s1)
    80002e3a:	2785                	addiw	a5,a5,1
    80002e3c:	c09c                	sw	a5,0(s1)
  // printf("hi");
  update_time();
    80002e3e:	00000097          	auipc	ra,0x0
    80002e42:	d6e080e7          	jalr	-658(ra) # 80002bac <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002e46:	8526                	mv	a0,s1
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	70e080e7          	jalr	1806(ra) # 80002556 <wakeup>
  release(&tickslock);
    80002e50:	854a                	mv	a0,s2
    80002e52:	ffffe097          	auipc	ra,0xffffe
    80002e56:	e9e080e7          	jalr	-354(ra) # 80000cf0 <release>
}
    80002e5a:	60e2                	ld	ra,24(sp)
    80002e5c:	6442                	ld	s0,16(sp)
    80002e5e:	64a2                	ld	s1,8(sp)
    80002e60:	6902                	ld	s2,0(sp)
    80002e62:	6105                	addi	sp,sp,32
    80002e64:	8082                	ret

0000000080002e66 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002e66:	1101                	addi	sp,sp,-32
    80002e68:	ec06                	sd	ra,24(sp)
    80002e6a:	e822                	sd	s0,16(sp)
    80002e6c:	e426                	sd	s1,8(sp)
    80002e6e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e70:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002e74:	00074d63          	bltz	a4,80002e8e <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002e78:	57fd                	li	a5,-1
    80002e7a:	17fe                	slli	a5,a5,0x3f
    80002e7c:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002e7e:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002e80:	06f70363          	beq	a4,a5,80002ee6 <devintr+0x80>
  }
}
    80002e84:	60e2                	ld	ra,24(sp)
    80002e86:	6442                	ld	s0,16(sp)
    80002e88:	64a2                	ld	s1,8(sp)
    80002e8a:	6105                	addi	sp,sp,32
    80002e8c:	8082                	ret
      (scause & 0xff) == 9)
    80002e8e:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002e92:	46a5                	li	a3,9
    80002e94:	fed792e3          	bne	a5,a3,80002e78 <devintr+0x12>
    int irq = plic_claim();
    80002e98:	00003097          	auipc	ra,0x3
    80002e9c:	680080e7          	jalr	1664(ra) # 80006518 <plic_claim>
    80002ea0:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002ea2:	47a9                	li	a5,10
    80002ea4:	02f50763          	beq	a0,a5,80002ed2 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002ea8:	4785                	li	a5,1
    80002eaa:	02f50963          	beq	a0,a5,80002edc <devintr+0x76>
    return 1;
    80002eae:	4505                	li	a0,1
    else if (irq)
    80002eb0:	d8f1                	beqz	s1,80002e84 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002eb2:	85a6                	mv	a1,s1
    80002eb4:	00005517          	auipc	a0,0x5
    80002eb8:	44c50513          	addi	a0,a0,1100 # 80008300 <states.0+0x38>
    80002ebc:	ffffd097          	auipc	ra,0xffffd
    80002ec0:	6cc080e7          	jalr	1740(ra) # 80000588 <printf>
      plic_complete(irq);
    80002ec4:	8526                	mv	a0,s1
    80002ec6:	00003097          	auipc	ra,0x3
    80002eca:	676080e7          	jalr	1654(ra) # 8000653c <plic_complete>
    return 1;
    80002ece:	4505                	li	a0,1
    80002ed0:	bf55                	j	80002e84 <devintr+0x1e>
      uartintr();
    80002ed2:	ffffe097          	auipc	ra,0xffffe
    80002ed6:	ac8080e7          	jalr	-1336(ra) # 8000099a <uartintr>
    80002eda:	b7ed                	j	80002ec4 <devintr+0x5e>
      virtio_disk_intr();
    80002edc:	00004097          	auipc	ra,0x4
    80002ee0:	b2c080e7          	jalr	-1236(ra) # 80006a08 <virtio_disk_intr>
    80002ee4:	b7c5                	j	80002ec4 <devintr+0x5e>
    if (cpuid() == 0)
    80002ee6:	fffff097          	auipc	ra,0xfffff
    80002eea:	bba080e7          	jalr	-1094(ra) # 80001aa0 <cpuid>
    80002eee:	c901                	beqz	a0,80002efe <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ef0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ef4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ef6:	14479073          	csrw	sip,a5
    return 2;
    80002efa:	4509                	li	a0,2
    80002efc:	b761                	j	80002e84 <devintr+0x1e>
      clockintr();
    80002efe:	00000097          	auipc	ra,0x0
    80002f02:	f14080e7          	jalr	-236(ra) # 80002e12 <clockintr>
    80002f06:	b7ed                	j	80002ef0 <devintr+0x8a>

0000000080002f08 <usertrap>:
{
    80002f08:	1101                	addi	sp,sp,-32
    80002f0a:	ec06                	sd	ra,24(sp)
    80002f0c:	e822                	sd	s0,16(sp)
    80002f0e:	e426                	sd	s1,8(sp)
    80002f10:	e04a                	sd	s2,0(sp)
    80002f12:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f14:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002f18:	1007f793          	andi	a5,a5,256
    80002f1c:	ebad                	bnez	a5,80002f8e <usertrap+0x86>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f1e:	00003797          	auipc	a5,0x3
    80002f22:	4f278793          	addi	a5,a5,1266 # 80006410 <kernelvec>
    80002f26:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	ba2080e7          	jalr	-1118(ra) # 80001acc <myproc>
    80002f32:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002f34:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f36:	14102773          	csrr	a4,sepc
    80002f3a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f3c:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002f40:	47a1                	li	a5,8
    80002f42:	04f70e63          	beq	a4,a5,80002f9e <usertrap+0x96>
    80002f46:	14202773          	csrr	a4,scause
  else if (r_scause() == 15)
    80002f4a:	47bd                	li	a5,15
    80002f4c:	08f71363          	bne	a4,a5,80002fd2 <usertrap+0xca>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f50:	143025f3          	csrr	a1,stval
    if (v >= p->sz)
    80002f54:	653c                	ld	a5,72(a0)
    80002f56:	00f5e463          	bltu	a1,a5,80002f5e <usertrap+0x56>
      p->killed = 1;
    80002f5a:	4785                	li	a5,1
    80002f5c:	d51c                	sw	a5,40(a0)
    int ret = cowtest_h(p->pagetable, v);
    80002f5e:	68a8                	ld	a0,80(s1)
    80002f60:	00000097          	auipc	ra,0x0
    80002f64:	d88080e7          	jalr	-632(ra) # 80002ce8 <cowtest_h>
    if (ret != 0)
    80002f68:	c119                	beqz	a0,80002f6e <usertrap+0x66>
      p->killed = 1;
    80002f6a:	4785                	li	a5,1
    80002f6c:	d49c                	sw	a5,40(s1)
  if (killed(p))
    80002f6e:	8526                	mv	a0,s1
    80002f70:	00000097          	auipc	ra,0x0
    80002f74:	836080e7          	jalr	-1994(ra) # 800027a6 <killed>
    80002f78:	e55d                	bnez	a0,80003026 <usertrap+0x11e>
  usertrapret();
    80002f7a:	00000097          	auipc	ra,0x0
    80002f7e:	e02080e7          	jalr	-510(ra) # 80002d7c <usertrapret>
}
    80002f82:	60e2                	ld	ra,24(sp)
    80002f84:	6442                	ld	s0,16(sp)
    80002f86:	64a2                	ld	s1,8(sp)
    80002f88:	6902                	ld	s2,0(sp)
    80002f8a:	6105                	addi	sp,sp,32
    80002f8c:	8082                	ret
    panic("usertrap: not from user mode");
    80002f8e:	00005517          	auipc	a0,0x5
    80002f92:	39250513          	addi	a0,a0,914 # 80008320 <states.0+0x58>
    80002f96:	ffffd097          	auipc	ra,0xffffd
    80002f9a:	5a8080e7          	jalr	1448(ra) # 8000053e <panic>
    if (killed(p))
    80002f9e:	00000097          	auipc	ra,0x0
    80002fa2:	808080e7          	jalr	-2040(ra) # 800027a6 <killed>
    80002fa6:	e105                	bnez	a0,80002fc6 <usertrap+0xbe>
    p->trapframe->epc += 4;
    80002fa8:	6cb8                	ld	a4,88(s1)
    80002faa:	6f1c                	ld	a5,24(a4)
    80002fac:	0791                	addi	a5,a5,4
    80002fae:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fb0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002fb4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fb8:	10079073          	csrw	sstatus,a5
    syscall();
    80002fbc:	00000097          	auipc	ra,0x0
    80002fc0:	2ea080e7          	jalr	746(ra) # 800032a6 <syscall>
    80002fc4:	b76d                	j	80002f6e <usertrap+0x66>
      exit(-1);
    80002fc6:	557d                	li	a0,-1
    80002fc8:	fffff097          	auipc	ra,0xfffff
    80002fcc:	65e080e7          	jalr	1630(ra) # 80002626 <exit>
    80002fd0:	bfe1                	j	80002fa8 <usertrap+0xa0>
  else if ((which_dev = devintr()) != 0)
    80002fd2:	00000097          	auipc	ra,0x0
    80002fd6:	e94080e7          	jalr	-364(ra) # 80002e66 <devintr>
    80002fda:	892a                	mv	s2,a0
    80002fdc:	c901                	beqz	a0,80002fec <usertrap+0xe4>
  if (killed(p))
    80002fde:	8526                	mv	a0,s1
    80002fe0:	fffff097          	auipc	ra,0xfffff
    80002fe4:	7c6080e7          	jalr	1990(ra) # 800027a6 <killed>
    80002fe8:	c529                	beqz	a0,80003032 <usertrap+0x12a>
    80002fea:	a83d                	j	80003028 <usertrap+0x120>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fec:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ff0:	5890                	lw	a2,48(s1)
    80002ff2:	00005517          	auipc	a0,0x5
    80002ff6:	34e50513          	addi	a0,a0,846 # 80008340 <states.0+0x78>
    80002ffa:	ffffd097          	auipc	ra,0xffffd
    80002ffe:	58e080e7          	jalr	1422(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003002:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003006:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000300a:	00005517          	auipc	a0,0x5
    8000300e:	36650513          	addi	a0,a0,870 # 80008370 <states.0+0xa8>
    80003012:	ffffd097          	auipc	ra,0xffffd
    80003016:	576080e7          	jalr	1398(ra) # 80000588 <printf>
    setkilled(p);
    8000301a:	8526                	mv	a0,s1
    8000301c:	fffff097          	auipc	ra,0xfffff
    80003020:	75e080e7          	jalr	1886(ra) # 8000277a <setkilled>
    80003024:	b7a9                	j	80002f6e <usertrap+0x66>
  if (killed(p))
    80003026:	4901                	li	s2,0
    exit(-1);
    80003028:	557d                	li	a0,-1
    8000302a:	fffff097          	auipc	ra,0xfffff
    8000302e:	5fc080e7          	jalr	1532(ra) # 80002626 <exit>
  if (which_dev == 2)
    80003032:	4789                	li	a5,2
    80003034:	f4f913e3          	bne	s2,a5,80002f7a <usertrap+0x72>
    yield();
    80003038:	fffff097          	auipc	ra,0xfffff
    8000303c:	47e080e7          	jalr	1150(ra) # 800024b6 <yield>
    80003040:	bf2d                	j	80002f7a <usertrap+0x72>

0000000080003042 <kerneltrap>:
{
    80003042:	7179                	addi	sp,sp,-48
    80003044:	f406                	sd	ra,40(sp)
    80003046:	f022                	sd	s0,32(sp)
    80003048:	ec26                	sd	s1,24(sp)
    8000304a:	e84a                	sd	s2,16(sp)
    8000304c:	e44e                	sd	s3,8(sp)
    8000304e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003050:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003054:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003058:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    8000305c:	1004f793          	andi	a5,s1,256
    80003060:	cb9d                	beqz	a5,80003096 <kerneltrap+0x54>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003062:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003066:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80003068:	ef9d                	bnez	a5,800030a6 <kerneltrap+0x64>
  if ((which_dev = devintr()) == 0)
    8000306a:	00000097          	auipc	ra,0x0
    8000306e:	dfc080e7          	jalr	-516(ra) # 80002e66 <devintr>
    80003072:	c131                	beqz	a0,800030b6 <kerneltrap+0x74>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003074:	4789                	li	a5,2
    80003076:	06f50d63          	beq	a0,a5,800030f0 <kerneltrap+0xae>
  if (which_dev == 1 && myproc() != 0 && myproc()->state == RUNNING)
    8000307a:	4785                	li	a5,1
    8000307c:	08f50c63          	beq	a0,a5,80003114 <kerneltrap+0xd2>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003080:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003084:	10049073          	csrw	sstatus,s1
}
    80003088:	70a2                	ld	ra,40(sp)
    8000308a:	7402                	ld	s0,32(sp)
    8000308c:	64e2                	ld	s1,24(sp)
    8000308e:	6942                	ld	s2,16(sp)
    80003090:	69a2                	ld	s3,8(sp)
    80003092:	6145                	addi	sp,sp,48
    80003094:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003096:	00005517          	auipc	a0,0x5
    8000309a:	2fa50513          	addi	a0,a0,762 # 80008390 <states.0+0xc8>
    8000309e:	ffffd097          	auipc	ra,0xffffd
    800030a2:	4a0080e7          	jalr	1184(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800030a6:	00005517          	auipc	a0,0x5
    800030aa:	31250513          	addi	a0,a0,786 # 800083b8 <states.0+0xf0>
    800030ae:	ffffd097          	auipc	ra,0xffffd
    800030b2:	490080e7          	jalr	1168(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800030b6:	85ce                	mv	a1,s3
    800030b8:	00005517          	auipc	a0,0x5
    800030bc:	32050513          	addi	a0,a0,800 # 800083d8 <states.0+0x110>
    800030c0:	ffffd097          	auipc	ra,0xffffd
    800030c4:	4c8080e7          	jalr	1224(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030c8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800030cc:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800030d0:	00005517          	auipc	a0,0x5
    800030d4:	31850513          	addi	a0,a0,792 # 800083e8 <states.0+0x120>
    800030d8:	ffffd097          	auipc	ra,0xffffd
    800030dc:	4b0080e7          	jalr	1200(ra) # 80000588 <printf>
    panic("kerneltrap");
    800030e0:	00005517          	auipc	a0,0x5
    800030e4:	32050513          	addi	a0,a0,800 # 80008400 <states.0+0x138>
    800030e8:	ffffd097          	auipc	ra,0xffffd
    800030ec:	456080e7          	jalr	1110(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800030f0:	fffff097          	auipc	ra,0xfffff
    800030f4:	9dc080e7          	jalr	-1572(ra) # 80001acc <myproc>
    800030f8:	d541                	beqz	a0,80003080 <kerneltrap+0x3e>
    800030fa:	fffff097          	auipc	ra,0xfffff
    800030fe:	9d2080e7          	jalr	-1582(ra) # 80001acc <myproc>
    80003102:	4d18                	lw	a4,24(a0)
    80003104:	4791                	li	a5,4
    80003106:	f6f71de3          	bne	a4,a5,80003080 <kerneltrap+0x3e>
    yield();
    8000310a:	fffff097          	auipc	ra,0xfffff
    8000310e:	3ac080e7          	jalr	940(ra) # 800024b6 <yield>
    80003112:	b7bd                	j	80003080 <kerneltrap+0x3e>
  if (which_dev == 1 && myproc() != 0 && myproc()->state == RUNNING)
    80003114:	fffff097          	auipc	ra,0xfffff
    80003118:	9b8080e7          	jalr	-1608(ra) # 80001acc <myproc>
    8000311c:	d135                	beqz	a0,80003080 <kerneltrap+0x3e>
    8000311e:	fffff097          	auipc	ra,0xfffff
    80003122:	9ae080e7          	jalr	-1618(ra) # 80001acc <myproc>
    80003126:	bfa9                	j	80003080 <kerneltrap+0x3e>

0000000080003128 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003128:	1101                	addi	sp,sp,-32
    8000312a:	ec06                	sd	ra,24(sp)
    8000312c:	e822                	sd	s0,16(sp)
    8000312e:	e426                	sd	s1,8(sp)
    80003130:	1000                	addi	s0,sp,32
    80003132:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003134:	fffff097          	auipc	ra,0xfffff
    80003138:	998080e7          	jalr	-1640(ra) # 80001acc <myproc>
  switch (n) {
    8000313c:	4795                	li	a5,5
    8000313e:	0497e163          	bltu	a5,s1,80003180 <argraw+0x58>
    80003142:	048a                	slli	s1,s1,0x2
    80003144:	00005717          	auipc	a4,0x5
    80003148:	2f470713          	addi	a4,a4,756 # 80008438 <states.0+0x170>
    8000314c:	94ba                	add	s1,s1,a4
    8000314e:	409c                	lw	a5,0(s1)
    80003150:	97ba                	add	a5,a5,a4
    80003152:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003154:	6d3c                	ld	a5,88(a0)
    80003156:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003158:	60e2                	ld	ra,24(sp)
    8000315a:	6442                	ld	s0,16(sp)
    8000315c:	64a2                	ld	s1,8(sp)
    8000315e:	6105                	addi	sp,sp,32
    80003160:	8082                	ret
    return p->trapframe->a1;
    80003162:	6d3c                	ld	a5,88(a0)
    80003164:	7fa8                	ld	a0,120(a5)
    80003166:	bfcd                	j	80003158 <argraw+0x30>
    return p->trapframe->a2;
    80003168:	6d3c                	ld	a5,88(a0)
    8000316a:	63c8                	ld	a0,128(a5)
    8000316c:	b7f5                	j	80003158 <argraw+0x30>
    return p->trapframe->a3;
    8000316e:	6d3c                	ld	a5,88(a0)
    80003170:	67c8                	ld	a0,136(a5)
    80003172:	b7dd                	j	80003158 <argraw+0x30>
    return p->trapframe->a4;
    80003174:	6d3c                	ld	a5,88(a0)
    80003176:	6bc8                	ld	a0,144(a5)
    80003178:	b7c5                	j	80003158 <argraw+0x30>
    return p->trapframe->a5;
    8000317a:	6d3c                	ld	a5,88(a0)
    8000317c:	6fc8                	ld	a0,152(a5)
    8000317e:	bfe9                	j	80003158 <argraw+0x30>
  panic("argraw");
    80003180:	00005517          	auipc	a0,0x5
    80003184:	29050513          	addi	a0,a0,656 # 80008410 <states.0+0x148>
    80003188:	ffffd097          	auipc	ra,0xffffd
    8000318c:	3b6080e7          	jalr	950(ra) # 8000053e <panic>

0000000080003190 <fetchaddr>:
{
    80003190:	1101                	addi	sp,sp,-32
    80003192:	ec06                	sd	ra,24(sp)
    80003194:	e822                	sd	s0,16(sp)
    80003196:	e426                	sd	s1,8(sp)
    80003198:	e04a                	sd	s2,0(sp)
    8000319a:	1000                	addi	s0,sp,32
    8000319c:	84aa                	mv	s1,a0
    8000319e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800031a0:	fffff097          	auipc	ra,0xfffff
    800031a4:	92c080e7          	jalr	-1748(ra) # 80001acc <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800031a8:	653c                	ld	a5,72(a0)
    800031aa:	02f4f863          	bgeu	s1,a5,800031da <fetchaddr+0x4a>
    800031ae:	00848713          	addi	a4,s1,8
    800031b2:	02e7e663          	bltu	a5,a4,800031de <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800031b6:	46a1                	li	a3,8
    800031b8:	8626                	mv	a2,s1
    800031ba:	85ca                	mv	a1,s2
    800031bc:	6928                	ld	a0,80(a0)
    800031be:	ffffe097          	auipc	ra,0xffffe
    800031c2:	656080e7          	jalr	1622(ra) # 80001814 <copyin>
    800031c6:	00a03533          	snez	a0,a0
    800031ca:	40a00533          	neg	a0,a0
}
    800031ce:	60e2                	ld	ra,24(sp)
    800031d0:	6442                	ld	s0,16(sp)
    800031d2:	64a2                	ld	s1,8(sp)
    800031d4:	6902                	ld	s2,0(sp)
    800031d6:	6105                	addi	sp,sp,32
    800031d8:	8082                	ret
    return -1;
    800031da:	557d                	li	a0,-1
    800031dc:	bfcd                	j	800031ce <fetchaddr+0x3e>
    800031de:	557d                	li	a0,-1
    800031e0:	b7fd                	j	800031ce <fetchaddr+0x3e>

00000000800031e2 <fetchstr>:
{
    800031e2:	7179                	addi	sp,sp,-48
    800031e4:	f406                	sd	ra,40(sp)
    800031e6:	f022                	sd	s0,32(sp)
    800031e8:	ec26                	sd	s1,24(sp)
    800031ea:	e84a                	sd	s2,16(sp)
    800031ec:	e44e                	sd	s3,8(sp)
    800031ee:	1800                	addi	s0,sp,48
    800031f0:	892a                	mv	s2,a0
    800031f2:	84ae                	mv	s1,a1
    800031f4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800031f6:	fffff097          	auipc	ra,0xfffff
    800031fa:	8d6080e7          	jalr	-1834(ra) # 80001acc <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800031fe:	86ce                	mv	a3,s3
    80003200:	864a                	mv	a2,s2
    80003202:	85a6                	mv	a1,s1
    80003204:	6928                	ld	a0,80(a0)
    80003206:	ffffe097          	auipc	ra,0xffffe
    8000320a:	69c080e7          	jalr	1692(ra) # 800018a2 <copyinstr>
    8000320e:	00054e63          	bltz	a0,8000322a <fetchstr+0x48>
  return strlen(buf);
    80003212:	8526                	mv	a0,s1
    80003214:	ffffe097          	auipc	ra,0xffffe
    80003218:	ca0080e7          	jalr	-864(ra) # 80000eb4 <strlen>
}
    8000321c:	70a2                	ld	ra,40(sp)
    8000321e:	7402                	ld	s0,32(sp)
    80003220:	64e2                	ld	s1,24(sp)
    80003222:	6942                	ld	s2,16(sp)
    80003224:	69a2                	ld	s3,8(sp)
    80003226:	6145                	addi	sp,sp,48
    80003228:	8082                	ret
    return -1;
    8000322a:	557d                	li	a0,-1
    8000322c:	bfc5                	j	8000321c <fetchstr+0x3a>

000000008000322e <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    8000322e:	1101                	addi	sp,sp,-32
    80003230:	ec06                	sd	ra,24(sp)
    80003232:	e822                	sd	s0,16(sp)
    80003234:	e426                	sd	s1,8(sp)
    80003236:	1000                	addi	s0,sp,32
    80003238:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000323a:	00000097          	auipc	ra,0x0
    8000323e:	eee080e7          	jalr	-274(ra) # 80003128 <argraw>
    80003242:	c088                	sw	a0,0(s1)
}
    80003244:	60e2                	ld	ra,24(sp)
    80003246:	6442                	ld	s0,16(sp)
    80003248:	64a2                	ld	s1,8(sp)
    8000324a:	6105                	addi	sp,sp,32
    8000324c:	8082                	ret

000000008000324e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    8000324e:	1101                	addi	sp,sp,-32
    80003250:	ec06                	sd	ra,24(sp)
    80003252:	e822                	sd	s0,16(sp)
    80003254:	e426                	sd	s1,8(sp)
    80003256:	1000                	addi	s0,sp,32
    80003258:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000325a:	00000097          	auipc	ra,0x0
    8000325e:	ece080e7          	jalr	-306(ra) # 80003128 <argraw>
    80003262:	e088                	sd	a0,0(s1)
}
    80003264:	60e2                	ld	ra,24(sp)
    80003266:	6442                	ld	s0,16(sp)
    80003268:	64a2                	ld	s1,8(sp)
    8000326a:	6105                	addi	sp,sp,32
    8000326c:	8082                	ret

000000008000326e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    8000326e:	7179                	addi	sp,sp,-48
    80003270:	f406                	sd	ra,40(sp)
    80003272:	f022                	sd	s0,32(sp)
    80003274:	ec26                	sd	s1,24(sp)
    80003276:	e84a                	sd	s2,16(sp)
    80003278:	1800                	addi	s0,sp,48
    8000327a:	84ae                	mv	s1,a1
    8000327c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    8000327e:	fd840593          	addi	a1,s0,-40
    80003282:	00000097          	auipc	ra,0x0
    80003286:	fcc080e7          	jalr	-52(ra) # 8000324e <argaddr>
  return fetchstr(addr, buf, max);
    8000328a:	864a                	mv	a2,s2
    8000328c:	85a6                	mv	a1,s1
    8000328e:	fd843503          	ld	a0,-40(s0)
    80003292:	00000097          	auipc	ra,0x0
    80003296:	f50080e7          	jalr	-176(ra) # 800031e2 <fetchstr>
}
    8000329a:	70a2                	ld	ra,40(sp)
    8000329c:	7402                	ld	s0,32(sp)
    8000329e:	64e2                	ld	s1,24(sp)
    800032a0:	6942                	ld	s2,16(sp)
    800032a2:	6145                	addi	sp,sp,48
    800032a4:	8082                	ret

00000000800032a6 <syscall>:
[SYS_set_priority] sys_set_priority,
};

void
syscall(void)
{
    800032a6:	1101                	addi	sp,sp,-32
    800032a8:	ec06                	sd	ra,24(sp)
    800032aa:	e822                	sd	s0,16(sp)
    800032ac:	e426                	sd	s1,8(sp)
    800032ae:	e04a                	sd	s2,0(sp)
    800032b0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800032b2:	fffff097          	auipc	ra,0xfffff
    800032b6:	81a080e7          	jalr	-2022(ra) # 80001acc <myproc>
    800032ba:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800032bc:	05853903          	ld	s2,88(a0)
    800032c0:	0a893783          	ld	a5,168(s2)
    800032c4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800032c8:	37fd                	addiw	a5,a5,-1
    800032ca:	475d                	li	a4,23
    800032cc:	00f76f63          	bltu	a4,a5,800032ea <syscall+0x44>
    800032d0:	00369713          	slli	a4,a3,0x3
    800032d4:	00005797          	auipc	a5,0x5
    800032d8:	17c78793          	addi	a5,a5,380 # 80008450 <syscalls>
    800032dc:	97ba                	add	a5,a5,a4
    800032de:	639c                	ld	a5,0(a5)
    800032e0:	c789                	beqz	a5,800032ea <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    800032e2:	9782                	jalr	a5
    800032e4:	06a93823          	sd	a0,112(s2)
    800032e8:	a839                	j	80003306 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800032ea:	15848613          	addi	a2,s1,344
    800032ee:	588c                	lw	a1,48(s1)
    800032f0:	00005517          	auipc	a0,0x5
    800032f4:	12850513          	addi	a0,a0,296 # 80008418 <states.0+0x150>
    800032f8:	ffffd097          	auipc	ra,0xffffd
    800032fc:	290080e7          	jalr	656(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003300:	6cbc                	ld	a5,88(s1)
    80003302:	577d                	li	a4,-1
    80003304:	fbb8                	sd	a4,112(a5)
  }
}
    80003306:	60e2                	ld	ra,24(sp)
    80003308:	6442                	ld	s0,16(sp)
    8000330a:	64a2                	ld	s1,8(sp)
    8000330c:	6902                	ld	s2,0(sp)
    8000330e:	6105                	addi	sp,sp,32
    80003310:	8082                	ret

0000000080003312 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003312:	1101                	addi	sp,sp,-32
    80003314:	ec06                	sd	ra,24(sp)
    80003316:	e822                	sd	s0,16(sp)
    80003318:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000331a:	fec40593          	addi	a1,s0,-20
    8000331e:	4501                	li	a0,0
    80003320:	00000097          	auipc	ra,0x0
    80003324:	f0e080e7          	jalr	-242(ra) # 8000322e <argint>
  exit(n);
    80003328:	fec42503          	lw	a0,-20(s0)
    8000332c:	fffff097          	auipc	ra,0xfffff
    80003330:	2fa080e7          	jalr	762(ra) # 80002626 <exit>
  return 0; // not reached
}
    80003334:	4501                	li	a0,0
    80003336:	60e2                	ld	ra,24(sp)
    80003338:	6442                	ld	s0,16(sp)
    8000333a:	6105                	addi	sp,sp,32
    8000333c:	8082                	ret

000000008000333e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000333e:	1141                	addi	sp,sp,-16
    80003340:	e406                	sd	ra,8(sp)
    80003342:	e022                	sd	s0,0(sp)
    80003344:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003346:	ffffe097          	auipc	ra,0xffffe
    8000334a:	786080e7          	jalr	1926(ra) # 80001acc <myproc>
}
    8000334e:	5908                	lw	a0,48(a0)
    80003350:	60a2                	ld	ra,8(sp)
    80003352:	6402                	ld	s0,0(sp)
    80003354:	0141                	addi	sp,sp,16
    80003356:	8082                	ret

0000000080003358 <sys_fork>:

uint64
sys_fork(void)
{
    80003358:	1141                	addi	sp,sp,-16
    8000335a:	e406                	sd	ra,8(sp)
    8000335c:	e022                	sd	s0,0(sp)
    8000335e:	0800                	addi	s0,sp,16
  return fork();
    80003360:	fffff097          	auipc	ra,0xfffff
    80003364:	b68080e7          	jalr	-1176(ra) # 80001ec8 <fork>
}
    80003368:	60a2                	ld	ra,8(sp)
    8000336a:	6402                	ld	s0,0(sp)
    8000336c:	0141                	addi	sp,sp,16
    8000336e:	8082                	ret

0000000080003370 <sys_wait>:

uint64
sys_wait(void)
{
    80003370:	1101                	addi	sp,sp,-32
    80003372:	ec06                	sd	ra,24(sp)
    80003374:	e822                	sd	s0,16(sp)
    80003376:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003378:	fe840593          	addi	a1,s0,-24
    8000337c:	4501                	li	a0,0
    8000337e:	00000097          	auipc	ra,0x0
    80003382:	ed0080e7          	jalr	-304(ra) # 8000324e <argaddr>
  return wait(p);
    80003386:	fe843503          	ld	a0,-24(s0)
    8000338a:	fffff097          	auipc	ra,0xfffff
    8000338e:	44e080e7          	jalr	1102(ra) # 800027d8 <wait>
}
    80003392:	60e2                	ld	ra,24(sp)
    80003394:	6442                	ld	s0,16(sp)
    80003396:	6105                	addi	sp,sp,32
    80003398:	8082                	ret

000000008000339a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000339a:	7179                	addi	sp,sp,-48
    8000339c:	f406                	sd	ra,40(sp)
    8000339e:	f022                	sd	s0,32(sp)
    800033a0:	ec26                	sd	s1,24(sp)
    800033a2:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800033a4:	fdc40593          	addi	a1,s0,-36
    800033a8:	4501                	li	a0,0
    800033aa:	00000097          	auipc	ra,0x0
    800033ae:	e84080e7          	jalr	-380(ra) # 8000322e <argint>
  addr = myproc()->sz;
    800033b2:	ffffe097          	auipc	ra,0xffffe
    800033b6:	71a080e7          	jalr	1818(ra) # 80001acc <myproc>
    800033ba:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800033bc:	fdc42503          	lw	a0,-36(s0)
    800033c0:	fffff097          	auipc	ra,0xfffff
    800033c4:	aac080e7          	jalr	-1364(ra) # 80001e6c <growproc>
    800033c8:	00054863          	bltz	a0,800033d8 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800033cc:	8526                	mv	a0,s1
    800033ce:	70a2                	ld	ra,40(sp)
    800033d0:	7402                	ld	s0,32(sp)
    800033d2:	64e2                	ld	s1,24(sp)
    800033d4:	6145                	addi	sp,sp,48
    800033d6:	8082                	ret
    return -1;
    800033d8:	54fd                	li	s1,-1
    800033da:	bfcd                	j	800033cc <sys_sbrk+0x32>

00000000800033dc <sys_sleep>:

uint64
sys_sleep(void)
{
    800033dc:	7139                	addi	sp,sp,-64
    800033de:	fc06                	sd	ra,56(sp)
    800033e0:	f822                	sd	s0,48(sp)
    800033e2:	f426                	sd	s1,40(sp)
    800033e4:	f04a                	sd	s2,32(sp)
    800033e6:	ec4e                	sd	s3,24(sp)
    800033e8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800033ea:	fcc40593          	addi	a1,s0,-52
    800033ee:	4501                	li	a0,0
    800033f0:	00000097          	auipc	ra,0x0
    800033f4:	e3e080e7          	jalr	-450(ra) # 8000322e <argint>
  acquire(&tickslock);
    800033f8:	00234517          	auipc	a0,0x234
    800033fc:	1a050513          	addi	a0,a0,416 # 80237598 <tickslock>
    80003400:	ffffe097          	auipc	ra,0xffffe
    80003404:	83c080e7          	jalr	-1988(ra) # 80000c3c <acquire>
  ticks0 = ticks;
    80003408:	00005917          	auipc	s2,0x5
    8000340c:	4d892903          	lw	s2,1240(s2) # 800088e0 <ticks>
  while (ticks - ticks0 < n)
    80003410:	fcc42783          	lw	a5,-52(s0)
    80003414:	cf9d                	beqz	a5,80003452 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003416:	00234997          	auipc	s3,0x234
    8000341a:	18298993          	addi	s3,s3,386 # 80237598 <tickslock>
    8000341e:	00005497          	auipc	s1,0x5
    80003422:	4c248493          	addi	s1,s1,1218 # 800088e0 <ticks>
    if (killed(myproc()))
    80003426:	ffffe097          	auipc	ra,0xffffe
    8000342a:	6a6080e7          	jalr	1702(ra) # 80001acc <myproc>
    8000342e:	fffff097          	auipc	ra,0xfffff
    80003432:	378080e7          	jalr	888(ra) # 800027a6 <killed>
    80003436:	ed15                	bnez	a0,80003472 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003438:	85ce                	mv	a1,s3
    8000343a:	8526                	mv	a0,s1
    8000343c:	fffff097          	auipc	ra,0xfffff
    80003440:	0b6080e7          	jalr	182(ra) # 800024f2 <sleep>
  while (ticks - ticks0 < n)
    80003444:	409c                	lw	a5,0(s1)
    80003446:	412787bb          	subw	a5,a5,s2
    8000344a:	fcc42703          	lw	a4,-52(s0)
    8000344e:	fce7ece3          	bltu	a5,a4,80003426 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003452:	00234517          	auipc	a0,0x234
    80003456:	14650513          	addi	a0,a0,326 # 80237598 <tickslock>
    8000345a:	ffffe097          	auipc	ra,0xffffe
    8000345e:	896080e7          	jalr	-1898(ra) # 80000cf0 <release>
  return 0;
    80003462:	4501                	li	a0,0
}
    80003464:	70e2                	ld	ra,56(sp)
    80003466:	7442                	ld	s0,48(sp)
    80003468:	74a2                	ld	s1,40(sp)
    8000346a:	7902                	ld	s2,32(sp)
    8000346c:	69e2                	ld	s3,24(sp)
    8000346e:	6121                	addi	sp,sp,64
    80003470:	8082                	ret
      release(&tickslock);
    80003472:	00234517          	auipc	a0,0x234
    80003476:	12650513          	addi	a0,a0,294 # 80237598 <tickslock>
    8000347a:	ffffe097          	auipc	ra,0xffffe
    8000347e:	876080e7          	jalr	-1930(ra) # 80000cf0 <release>
      return -1;
    80003482:	557d                	li	a0,-1
    80003484:	b7c5                	j	80003464 <sys_sleep+0x88>

0000000080003486 <sys_kill>:

uint64
sys_kill(void)
{
    80003486:	1101                	addi	sp,sp,-32
    80003488:	ec06                	sd	ra,24(sp)
    8000348a:	e822                	sd	s0,16(sp)
    8000348c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000348e:	fec40593          	addi	a1,s0,-20
    80003492:	4501                	li	a0,0
    80003494:	00000097          	auipc	ra,0x0
    80003498:	d9a080e7          	jalr	-614(ra) # 8000322e <argint>
  return kill(pid);
    8000349c:	fec42503          	lw	a0,-20(s0)
    800034a0:	fffff097          	auipc	ra,0xfffff
    800034a4:	268080e7          	jalr	616(ra) # 80002708 <kill>
}
    800034a8:	60e2                	ld	ra,24(sp)
    800034aa:	6442                	ld	s0,16(sp)
    800034ac:	6105                	addi	sp,sp,32
    800034ae:	8082                	ret

00000000800034b0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800034b0:	1101                	addi	sp,sp,-32
    800034b2:	ec06                	sd	ra,24(sp)
    800034b4:	e822                	sd	s0,16(sp)
    800034b6:	e426                	sd	s1,8(sp)
    800034b8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800034ba:	00234517          	auipc	a0,0x234
    800034be:	0de50513          	addi	a0,a0,222 # 80237598 <tickslock>
    800034c2:	ffffd097          	auipc	ra,0xffffd
    800034c6:	77a080e7          	jalr	1914(ra) # 80000c3c <acquire>
  xticks = ticks;
    800034ca:	00005497          	auipc	s1,0x5
    800034ce:	4164a483          	lw	s1,1046(s1) # 800088e0 <ticks>
  release(&tickslock);
    800034d2:	00234517          	auipc	a0,0x234
    800034d6:	0c650513          	addi	a0,a0,198 # 80237598 <tickslock>
    800034da:	ffffe097          	auipc	ra,0xffffe
    800034de:	816080e7          	jalr	-2026(ra) # 80000cf0 <release>
  return xticks;
}
    800034e2:	02049513          	slli	a0,s1,0x20
    800034e6:	9101                	srli	a0,a0,0x20
    800034e8:	60e2                	ld	ra,24(sp)
    800034ea:	6442                	ld	s0,16(sp)
    800034ec:	64a2                	ld	s1,8(sp)
    800034ee:	6105                	addi	sp,sp,32
    800034f0:	8082                	ret

00000000800034f2 <sys_waitx>:

uint64
sys_waitx(void)
{
    800034f2:	7139                	addi	sp,sp,-64
    800034f4:	fc06                	sd	ra,56(sp)
    800034f6:	f822                	sd	s0,48(sp)
    800034f8:	f426                	sd	s1,40(sp)
    800034fa:	f04a                	sd	s2,32(sp)
    800034fc:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800034fe:	fd840593          	addi	a1,s0,-40
    80003502:	4501                	li	a0,0
    80003504:	00000097          	auipc	ra,0x0
    80003508:	d4a080e7          	jalr	-694(ra) # 8000324e <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000350c:	fd040593          	addi	a1,s0,-48
    80003510:	4505                	li	a0,1
    80003512:	00000097          	auipc	ra,0x0
    80003516:	d3c080e7          	jalr	-708(ra) # 8000324e <argaddr>
  argaddr(2, &addr2);
    8000351a:	fc840593          	addi	a1,s0,-56
    8000351e:	4509                	li	a0,2
    80003520:	00000097          	auipc	ra,0x0
    80003524:	d2e080e7          	jalr	-722(ra) # 8000324e <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003528:	fc040613          	addi	a2,s0,-64
    8000352c:	fc440593          	addi	a1,s0,-60
    80003530:	fd843503          	ld	a0,-40(s0)
    80003534:	fffff097          	auipc	ra,0xfffff
    80003538:	52c080e7          	jalr	1324(ra) # 80002a60 <waitx>
    8000353c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000353e:	ffffe097          	auipc	ra,0xffffe
    80003542:	58e080e7          	jalr	1422(ra) # 80001acc <myproc>
    80003546:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003548:	4691                	li	a3,4
    8000354a:	fc440613          	addi	a2,s0,-60
    8000354e:	fd043583          	ld	a1,-48(s0)
    80003552:	6928                	ld	a0,80(a0)
    80003554:	ffffe097          	auipc	ra,0xffffe
    80003558:	1a0080e7          	jalr	416(ra) # 800016f4 <copyout>
    return -1;
    8000355c:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000355e:	00054f63          	bltz	a0,8000357c <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003562:	4691                	li	a3,4
    80003564:	fc040613          	addi	a2,s0,-64
    80003568:	fc843583          	ld	a1,-56(s0)
    8000356c:	68a8                	ld	a0,80(s1)
    8000356e:	ffffe097          	auipc	ra,0xffffe
    80003572:	186080e7          	jalr	390(ra) # 800016f4 <copyout>
    80003576:	00054a63          	bltz	a0,8000358a <sys_waitx+0x98>
    return -1;
  return ret;
    8000357a:	87ca                	mv	a5,s2
    8000357c:	853e                	mv	a0,a5
    8000357e:	70e2                	ld	ra,56(sp)
    80003580:	7442                	ld	s0,48(sp)
    80003582:	74a2                	ld	s1,40(sp)
    80003584:	7902                	ld	s2,32(sp)
    80003586:	6121                	addi	sp,sp,64
    80003588:	8082                	ret
    return -1;
    8000358a:	57fd                	li	a5,-1
    8000358c:	bfc5                	j	8000357c <sys_waitx+0x8a>

000000008000358e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000358e:	7179                	addi	sp,sp,-48
    80003590:	f406                	sd	ra,40(sp)
    80003592:	f022                	sd	s0,32(sp)
    80003594:	ec26                	sd	s1,24(sp)
    80003596:	e84a                	sd	s2,16(sp)
    80003598:	e44e                	sd	s3,8(sp)
    8000359a:	e052                	sd	s4,0(sp)
    8000359c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000359e:	00005597          	auipc	a1,0x5
    800035a2:	f7a58593          	addi	a1,a1,-134 # 80008518 <syscalls+0xc8>
    800035a6:	00234517          	auipc	a0,0x234
    800035aa:	00a50513          	addi	a0,a0,10 # 802375b0 <bcache>
    800035ae:	ffffd097          	auipc	ra,0xffffd
    800035b2:	5fe080e7          	jalr	1534(ra) # 80000bac <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800035b6:	0023c797          	auipc	a5,0x23c
    800035ba:	ffa78793          	addi	a5,a5,-6 # 8023f5b0 <bcache+0x8000>
    800035be:	0023c717          	auipc	a4,0x23c
    800035c2:	25a70713          	addi	a4,a4,602 # 8023f818 <bcache+0x8268>
    800035c6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800035ca:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035ce:	00234497          	auipc	s1,0x234
    800035d2:	ffa48493          	addi	s1,s1,-6 # 802375c8 <bcache+0x18>
    b->next = bcache.head.next;
    800035d6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800035d8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800035da:	00005a17          	auipc	s4,0x5
    800035de:	f46a0a13          	addi	s4,s4,-186 # 80008520 <syscalls+0xd0>
    b->next = bcache.head.next;
    800035e2:	2b893783          	ld	a5,696(s2)
    800035e6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035e8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800035ec:	85d2                	mv	a1,s4
    800035ee:	01048513          	addi	a0,s1,16
    800035f2:	00001097          	auipc	ra,0x1
    800035f6:	4c4080e7          	jalr	1220(ra) # 80004ab6 <initsleeplock>
    bcache.head.next->prev = b;
    800035fa:	2b893783          	ld	a5,696(s2)
    800035fe:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003600:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003604:	45848493          	addi	s1,s1,1112
    80003608:	fd349de3          	bne	s1,s3,800035e2 <binit+0x54>
  }
}
    8000360c:	70a2                	ld	ra,40(sp)
    8000360e:	7402                	ld	s0,32(sp)
    80003610:	64e2                	ld	s1,24(sp)
    80003612:	6942                	ld	s2,16(sp)
    80003614:	69a2                	ld	s3,8(sp)
    80003616:	6a02                	ld	s4,0(sp)
    80003618:	6145                	addi	sp,sp,48
    8000361a:	8082                	ret

000000008000361c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000361c:	7179                	addi	sp,sp,-48
    8000361e:	f406                	sd	ra,40(sp)
    80003620:	f022                	sd	s0,32(sp)
    80003622:	ec26                	sd	s1,24(sp)
    80003624:	e84a                	sd	s2,16(sp)
    80003626:	e44e                	sd	s3,8(sp)
    80003628:	1800                	addi	s0,sp,48
    8000362a:	892a                	mv	s2,a0
    8000362c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000362e:	00234517          	auipc	a0,0x234
    80003632:	f8250513          	addi	a0,a0,-126 # 802375b0 <bcache>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	606080e7          	jalr	1542(ra) # 80000c3c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000363e:	0023c497          	auipc	s1,0x23c
    80003642:	22a4b483          	ld	s1,554(s1) # 8023f868 <bcache+0x82b8>
    80003646:	0023c797          	auipc	a5,0x23c
    8000364a:	1d278793          	addi	a5,a5,466 # 8023f818 <bcache+0x8268>
    8000364e:	02f48f63          	beq	s1,a5,8000368c <bread+0x70>
    80003652:	873e                	mv	a4,a5
    80003654:	a021                	j	8000365c <bread+0x40>
    80003656:	68a4                	ld	s1,80(s1)
    80003658:	02e48a63          	beq	s1,a4,8000368c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000365c:	449c                	lw	a5,8(s1)
    8000365e:	ff279ce3          	bne	a5,s2,80003656 <bread+0x3a>
    80003662:	44dc                	lw	a5,12(s1)
    80003664:	ff3799e3          	bne	a5,s3,80003656 <bread+0x3a>
      b->refcnt++;
    80003668:	40bc                	lw	a5,64(s1)
    8000366a:	2785                	addiw	a5,a5,1
    8000366c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000366e:	00234517          	auipc	a0,0x234
    80003672:	f4250513          	addi	a0,a0,-190 # 802375b0 <bcache>
    80003676:	ffffd097          	auipc	ra,0xffffd
    8000367a:	67a080e7          	jalr	1658(ra) # 80000cf0 <release>
      acquiresleep(&b->lock);
    8000367e:	01048513          	addi	a0,s1,16
    80003682:	00001097          	auipc	ra,0x1
    80003686:	46e080e7          	jalr	1134(ra) # 80004af0 <acquiresleep>
      return b;
    8000368a:	a8b9                	j	800036e8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000368c:	0023c497          	auipc	s1,0x23c
    80003690:	1d44b483          	ld	s1,468(s1) # 8023f860 <bcache+0x82b0>
    80003694:	0023c797          	auipc	a5,0x23c
    80003698:	18478793          	addi	a5,a5,388 # 8023f818 <bcache+0x8268>
    8000369c:	00f48863          	beq	s1,a5,800036ac <bread+0x90>
    800036a0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800036a2:	40bc                	lw	a5,64(s1)
    800036a4:	cf81                	beqz	a5,800036bc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036a6:	64a4                	ld	s1,72(s1)
    800036a8:	fee49de3          	bne	s1,a4,800036a2 <bread+0x86>
  panic("bget: no buffers");
    800036ac:	00005517          	auipc	a0,0x5
    800036b0:	e7c50513          	addi	a0,a0,-388 # 80008528 <syscalls+0xd8>
    800036b4:	ffffd097          	auipc	ra,0xffffd
    800036b8:	e8a080e7          	jalr	-374(ra) # 8000053e <panic>
      b->dev = dev;
    800036bc:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800036c0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800036c4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800036c8:	4785                	li	a5,1
    800036ca:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036cc:	00234517          	auipc	a0,0x234
    800036d0:	ee450513          	addi	a0,a0,-284 # 802375b0 <bcache>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	61c080e7          	jalr	1564(ra) # 80000cf0 <release>
      acquiresleep(&b->lock);
    800036dc:	01048513          	addi	a0,s1,16
    800036e0:	00001097          	auipc	ra,0x1
    800036e4:	410080e7          	jalr	1040(ra) # 80004af0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036e8:	409c                	lw	a5,0(s1)
    800036ea:	cb89                	beqz	a5,800036fc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800036ec:	8526                	mv	a0,s1
    800036ee:	70a2                	ld	ra,40(sp)
    800036f0:	7402                	ld	s0,32(sp)
    800036f2:	64e2                	ld	s1,24(sp)
    800036f4:	6942                	ld	s2,16(sp)
    800036f6:	69a2                	ld	s3,8(sp)
    800036f8:	6145                	addi	sp,sp,48
    800036fa:	8082                	ret
    virtio_disk_rw(b, 0);
    800036fc:	4581                	li	a1,0
    800036fe:	8526                	mv	a0,s1
    80003700:	00003097          	auipc	ra,0x3
    80003704:	0d4080e7          	jalr	212(ra) # 800067d4 <virtio_disk_rw>
    b->valid = 1;
    80003708:	4785                	li	a5,1
    8000370a:	c09c                	sw	a5,0(s1)
  return b;
    8000370c:	b7c5                	j	800036ec <bread+0xd0>

000000008000370e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000370e:	1101                	addi	sp,sp,-32
    80003710:	ec06                	sd	ra,24(sp)
    80003712:	e822                	sd	s0,16(sp)
    80003714:	e426                	sd	s1,8(sp)
    80003716:	1000                	addi	s0,sp,32
    80003718:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000371a:	0541                	addi	a0,a0,16
    8000371c:	00001097          	auipc	ra,0x1
    80003720:	46e080e7          	jalr	1134(ra) # 80004b8a <holdingsleep>
    80003724:	cd01                	beqz	a0,8000373c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003726:	4585                	li	a1,1
    80003728:	8526                	mv	a0,s1
    8000372a:	00003097          	auipc	ra,0x3
    8000372e:	0aa080e7          	jalr	170(ra) # 800067d4 <virtio_disk_rw>
}
    80003732:	60e2                	ld	ra,24(sp)
    80003734:	6442                	ld	s0,16(sp)
    80003736:	64a2                	ld	s1,8(sp)
    80003738:	6105                	addi	sp,sp,32
    8000373a:	8082                	ret
    panic("bwrite");
    8000373c:	00005517          	auipc	a0,0x5
    80003740:	e0450513          	addi	a0,a0,-508 # 80008540 <syscalls+0xf0>
    80003744:	ffffd097          	auipc	ra,0xffffd
    80003748:	dfa080e7          	jalr	-518(ra) # 8000053e <panic>

000000008000374c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000374c:	1101                	addi	sp,sp,-32
    8000374e:	ec06                	sd	ra,24(sp)
    80003750:	e822                	sd	s0,16(sp)
    80003752:	e426                	sd	s1,8(sp)
    80003754:	e04a                	sd	s2,0(sp)
    80003756:	1000                	addi	s0,sp,32
    80003758:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000375a:	01050913          	addi	s2,a0,16
    8000375e:	854a                	mv	a0,s2
    80003760:	00001097          	auipc	ra,0x1
    80003764:	42a080e7          	jalr	1066(ra) # 80004b8a <holdingsleep>
    80003768:	c92d                	beqz	a0,800037da <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000376a:	854a                	mv	a0,s2
    8000376c:	00001097          	auipc	ra,0x1
    80003770:	3da080e7          	jalr	986(ra) # 80004b46 <releasesleep>

  acquire(&bcache.lock);
    80003774:	00234517          	auipc	a0,0x234
    80003778:	e3c50513          	addi	a0,a0,-452 # 802375b0 <bcache>
    8000377c:	ffffd097          	auipc	ra,0xffffd
    80003780:	4c0080e7          	jalr	1216(ra) # 80000c3c <acquire>
  b->refcnt--;
    80003784:	40bc                	lw	a5,64(s1)
    80003786:	37fd                	addiw	a5,a5,-1
    80003788:	0007871b          	sext.w	a4,a5
    8000378c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000378e:	eb05                	bnez	a4,800037be <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003790:	68bc                	ld	a5,80(s1)
    80003792:	64b8                	ld	a4,72(s1)
    80003794:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003796:	64bc                	ld	a5,72(s1)
    80003798:	68b8                	ld	a4,80(s1)
    8000379a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000379c:	0023c797          	auipc	a5,0x23c
    800037a0:	e1478793          	addi	a5,a5,-492 # 8023f5b0 <bcache+0x8000>
    800037a4:	2b87b703          	ld	a4,696(a5)
    800037a8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800037aa:	0023c717          	auipc	a4,0x23c
    800037ae:	06e70713          	addi	a4,a4,110 # 8023f818 <bcache+0x8268>
    800037b2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800037b4:	2b87b703          	ld	a4,696(a5)
    800037b8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800037ba:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800037be:	00234517          	auipc	a0,0x234
    800037c2:	df250513          	addi	a0,a0,-526 # 802375b0 <bcache>
    800037c6:	ffffd097          	auipc	ra,0xffffd
    800037ca:	52a080e7          	jalr	1322(ra) # 80000cf0 <release>
}
    800037ce:	60e2                	ld	ra,24(sp)
    800037d0:	6442                	ld	s0,16(sp)
    800037d2:	64a2                	ld	s1,8(sp)
    800037d4:	6902                	ld	s2,0(sp)
    800037d6:	6105                	addi	sp,sp,32
    800037d8:	8082                	ret
    panic("brelse");
    800037da:	00005517          	auipc	a0,0x5
    800037de:	d6e50513          	addi	a0,a0,-658 # 80008548 <syscalls+0xf8>
    800037e2:	ffffd097          	auipc	ra,0xffffd
    800037e6:	d5c080e7          	jalr	-676(ra) # 8000053e <panic>

00000000800037ea <bpin>:

void
bpin(struct buf *b) {
    800037ea:	1101                	addi	sp,sp,-32
    800037ec:	ec06                	sd	ra,24(sp)
    800037ee:	e822                	sd	s0,16(sp)
    800037f0:	e426                	sd	s1,8(sp)
    800037f2:	1000                	addi	s0,sp,32
    800037f4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037f6:	00234517          	auipc	a0,0x234
    800037fa:	dba50513          	addi	a0,a0,-582 # 802375b0 <bcache>
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	43e080e7          	jalr	1086(ra) # 80000c3c <acquire>
  b->refcnt++;
    80003806:	40bc                	lw	a5,64(s1)
    80003808:	2785                	addiw	a5,a5,1
    8000380a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000380c:	00234517          	auipc	a0,0x234
    80003810:	da450513          	addi	a0,a0,-604 # 802375b0 <bcache>
    80003814:	ffffd097          	auipc	ra,0xffffd
    80003818:	4dc080e7          	jalr	1244(ra) # 80000cf0 <release>
}
    8000381c:	60e2                	ld	ra,24(sp)
    8000381e:	6442                	ld	s0,16(sp)
    80003820:	64a2                	ld	s1,8(sp)
    80003822:	6105                	addi	sp,sp,32
    80003824:	8082                	ret

0000000080003826 <bunpin>:

void
bunpin(struct buf *b) {
    80003826:	1101                	addi	sp,sp,-32
    80003828:	ec06                	sd	ra,24(sp)
    8000382a:	e822                	sd	s0,16(sp)
    8000382c:	e426                	sd	s1,8(sp)
    8000382e:	1000                	addi	s0,sp,32
    80003830:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003832:	00234517          	auipc	a0,0x234
    80003836:	d7e50513          	addi	a0,a0,-642 # 802375b0 <bcache>
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	402080e7          	jalr	1026(ra) # 80000c3c <acquire>
  b->refcnt--;
    80003842:	40bc                	lw	a5,64(s1)
    80003844:	37fd                	addiw	a5,a5,-1
    80003846:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003848:	00234517          	auipc	a0,0x234
    8000384c:	d6850513          	addi	a0,a0,-664 # 802375b0 <bcache>
    80003850:	ffffd097          	auipc	ra,0xffffd
    80003854:	4a0080e7          	jalr	1184(ra) # 80000cf0 <release>
}
    80003858:	60e2                	ld	ra,24(sp)
    8000385a:	6442                	ld	s0,16(sp)
    8000385c:	64a2                	ld	s1,8(sp)
    8000385e:	6105                	addi	sp,sp,32
    80003860:	8082                	ret

0000000080003862 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003862:	1101                	addi	sp,sp,-32
    80003864:	ec06                	sd	ra,24(sp)
    80003866:	e822                	sd	s0,16(sp)
    80003868:	e426                	sd	s1,8(sp)
    8000386a:	e04a                	sd	s2,0(sp)
    8000386c:	1000                	addi	s0,sp,32
    8000386e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003870:	00d5d59b          	srliw	a1,a1,0xd
    80003874:	0023c797          	auipc	a5,0x23c
    80003878:	4187a783          	lw	a5,1048(a5) # 8023fc8c <sb+0x1c>
    8000387c:	9dbd                	addw	a1,a1,a5
    8000387e:	00000097          	auipc	ra,0x0
    80003882:	d9e080e7          	jalr	-610(ra) # 8000361c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003886:	0074f713          	andi	a4,s1,7
    8000388a:	4785                	li	a5,1
    8000388c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003890:	14ce                	slli	s1,s1,0x33
    80003892:	90d9                	srli	s1,s1,0x36
    80003894:	00950733          	add	a4,a0,s1
    80003898:	05874703          	lbu	a4,88(a4)
    8000389c:	00e7f6b3          	and	a3,a5,a4
    800038a0:	c69d                	beqz	a3,800038ce <bfree+0x6c>
    800038a2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800038a4:	94aa                	add	s1,s1,a0
    800038a6:	fff7c793          	not	a5,a5
    800038aa:	8ff9                	and	a5,a5,a4
    800038ac:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800038b0:	00001097          	auipc	ra,0x1
    800038b4:	120080e7          	jalr	288(ra) # 800049d0 <log_write>
  brelse(bp);
    800038b8:	854a                	mv	a0,s2
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	e92080e7          	jalr	-366(ra) # 8000374c <brelse>
}
    800038c2:	60e2                	ld	ra,24(sp)
    800038c4:	6442                	ld	s0,16(sp)
    800038c6:	64a2                	ld	s1,8(sp)
    800038c8:	6902                	ld	s2,0(sp)
    800038ca:	6105                	addi	sp,sp,32
    800038cc:	8082                	ret
    panic("freeing free block");
    800038ce:	00005517          	auipc	a0,0x5
    800038d2:	c8250513          	addi	a0,a0,-894 # 80008550 <syscalls+0x100>
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	c68080e7          	jalr	-920(ra) # 8000053e <panic>

00000000800038de <balloc>:
{
    800038de:	711d                	addi	sp,sp,-96
    800038e0:	ec86                	sd	ra,88(sp)
    800038e2:	e8a2                	sd	s0,80(sp)
    800038e4:	e4a6                	sd	s1,72(sp)
    800038e6:	e0ca                	sd	s2,64(sp)
    800038e8:	fc4e                	sd	s3,56(sp)
    800038ea:	f852                	sd	s4,48(sp)
    800038ec:	f456                	sd	s5,40(sp)
    800038ee:	f05a                	sd	s6,32(sp)
    800038f0:	ec5e                	sd	s7,24(sp)
    800038f2:	e862                	sd	s8,16(sp)
    800038f4:	e466                	sd	s9,8(sp)
    800038f6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800038f8:	0023c797          	auipc	a5,0x23c
    800038fc:	37c7a783          	lw	a5,892(a5) # 8023fc74 <sb+0x4>
    80003900:	10078163          	beqz	a5,80003a02 <balloc+0x124>
    80003904:	8baa                	mv	s7,a0
    80003906:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003908:	0023cb17          	auipc	s6,0x23c
    8000390c:	368b0b13          	addi	s6,s6,872 # 8023fc70 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003910:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003912:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003914:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003916:	6c89                	lui	s9,0x2
    80003918:	a061                	j	800039a0 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000391a:	974a                	add	a4,a4,s2
    8000391c:	8fd5                	or	a5,a5,a3
    8000391e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003922:	854a                	mv	a0,s2
    80003924:	00001097          	auipc	ra,0x1
    80003928:	0ac080e7          	jalr	172(ra) # 800049d0 <log_write>
        brelse(bp);
    8000392c:	854a                	mv	a0,s2
    8000392e:	00000097          	auipc	ra,0x0
    80003932:	e1e080e7          	jalr	-482(ra) # 8000374c <brelse>
  bp = bread(dev, bno);
    80003936:	85a6                	mv	a1,s1
    80003938:	855e                	mv	a0,s7
    8000393a:	00000097          	auipc	ra,0x0
    8000393e:	ce2080e7          	jalr	-798(ra) # 8000361c <bread>
    80003942:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003944:	40000613          	li	a2,1024
    80003948:	4581                	li	a1,0
    8000394a:	05850513          	addi	a0,a0,88
    8000394e:	ffffd097          	auipc	ra,0xffffd
    80003952:	3ea080e7          	jalr	1002(ra) # 80000d38 <memset>
  log_write(bp);
    80003956:	854a                	mv	a0,s2
    80003958:	00001097          	auipc	ra,0x1
    8000395c:	078080e7          	jalr	120(ra) # 800049d0 <log_write>
  brelse(bp);
    80003960:	854a                	mv	a0,s2
    80003962:	00000097          	auipc	ra,0x0
    80003966:	dea080e7          	jalr	-534(ra) # 8000374c <brelse>
}
    8000396a:	8526                	mv	a0,s1
    8000396c:	60e6                	ld	ra,88(sp)
    8000396e:	6446                	ld	s0,80(sp)
    80003970:	64a6                	ld	s1,72(sp)
    80003972:	6906                	ld	s2,64(sp)
    80003974:	79e2                	ld	s3,56(sp)
    80003976:	7a42                	ld	s4,48(sp)
    80003978:	7aa2                	ld	s5,40(sp)
    8000397a:	7b02                	ld	s6,32(sp)
    8000397c:	6be2                	ld	s7,24(sp)
    8000397e:	6c42                	ld	s8,16(sp)
    80003980:	6ca2                	ld	s9,8(sp)
    80003982:	6125                	addi	sp,sp,96
    80003984:	8082                	ret
    brelse(bp);
    80003986:	854a                	mv	a0,s2
    80003988:	00000097          	auipc	ra,0x0
    8000398c:	dc4080e7          	jalr	-572(ra) # 8000374c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003990:	015c87bb          	addw	a5,s9,s5
    80003994:	00078a9b          	sext.w	s5,a5
    80003998:	004b2703          	lw	a4,4(s6)
    8000399c:	06eaf363          	bgeu	s5,a4,80003a02 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800039a0:	41fad79b          	sraiw	a5,s5,0x1f
    800039a4:	0137d79b          	srliw	a5,a5,0x13
    800039a8:	015787bb          	addw	a5,a5,s5
    800039ac:	40d7d79b          	sraiw	a5,a5,0xd
    800039b0:	01cb2583          	lw	a1,28(s6)
    800039b4:	9dbd                	addw	a1,a1,a5
    800039b6:	855e                	mv	a0,s7
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	c64080e7          	jalr	-924(ra) # 8000361c <bread>
    800039c0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039c2:	004b2503          	lw	a0,4(s6)
    800039c6:	000a849b          	sext.w	s1,s5
    800039ca:	8662                	mv	a2,s8
    800039cc:	faa4fde3          	bgeu	s1,a0,80003986 <balloc+0xa8>
      m = 1 << (bi % 8);
    800039d0:	41f6579b          	sraiw	a5,a2,0x1f
    800039d4:	01d7d69b          	srliw	a3,a5,0x1d
    800039d8:	00c6873b          	addw	a4,a3,a2
    800039dc:	00777793          	andi	a5,a4,7
    800039e0:	9f95                	subw	a5,a5,a3
    800039e2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800039e6:	4037571b          	sraiw	a4,a4,0x3
    800039ea:	00e906b3          	add	a3,s2,a4
    800039ee:	0586c683          	lbu	a3,88(a3)
    800039f2:	00d7f5b3          	and	a1,a5,a3
    800039f6:	d195                	beqz	a1,8000391a <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039f8:	2605                	addiw	a2,a2,1
    800039fa:	2485                	addiw	s1,s1,1
    800039fc:	fd4618e3          	bne	a2,s4,800039cc <balloc+0xee>
    80003a00:	b759                	j	80003986 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003a02:	00005517          	auipc	a0,0x5
    80003a06:	b6650513          	addi	a0,a0,-1178 # 80008568 <syscalls+0x118>
    80003a0a:	ffffd097          	auipc	ra,0xffffd
    80003a0e:	b7e080e7          	jalr	-1154(ra) # 80000588 <printf>
  return 0;
    80003a12:	4481                	li	s1,0
    80003a14:	bf99                	j	8000396a <balloc+0x8c>

0000000080003a16 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a16:	7179                	addi	sp,sp,-48
    80003a18:	f406                	sd	ra,40(sp)
    80003a1a:	f022                	sd	s0,32(sp)
    80003a1c:	ec26                	sd	s1,24(sp)
    80003a1e:	e84a                	sd	s2,16(sp)
    80003a20:	e44e                	sd	s3,8(sp)
    80003a22:	e052                	sd	s4,0(sp)
    80003a24:	1800                	addi	s0,sp,48
    80003a26:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a28:	47ad                	li	a5,11
    80003a2a:	02b7e763          	bltu	a5,a1,80003a58 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003a2e:	02059493          	slli	s1,a1,0x20
    80003a32:	9081                	srli	s1,s1,0x20
    80003a34:	048a                	slli	s1,s1,0x2
    80003a36:	94aa                	add	s1,s1,a0
    80003a38:	0504a903          	lw	s2,80(s1)
    80003a3c:	06091e63          	bnez	s2,80003ab8 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003a40:	4108                	lw	a0,0(a0)
    80003a42:	00000097          	auipc	ra,0x0
    80003a46:	e9c080e7          	jalr	-356(ra) # 800038de <balloc>
    80003a4a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003a4e:	06090563          	beqz	s2,80003ab8 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003a52:	0524a823          	sw	s2,80(s1)
    80003a56:	a08d                	j	80003ab8 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003a58:	ff45849b          	addiw	s1,a1,-12
    80003a5c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a60:	0ff00793          	li	a5,255
    80003a64:	08e7e563          	bltu	a5,a4,80003aee <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003a68:	08052903          	lw	s2,128(a0)
    80003a6c:	00091d63          	bnez	s2,80003a86 <bmap+0x70>
      addr = balloc(ip->dev);
    80003a70:	4108                	lw	a0,0(a0)
    80003a72:	00000097          	auipc	ra,0x0
    80003a76:	e6c080e7          	jalr	-404(ra) # 800038de <balloc>
    80003a7a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003a7e:	02090d63          	beqz	s2,80003ab8 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003a82:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003a86:	85ca                	mv	a1,s2
    80003a88:	0009a503          	lw	a0,0(s3)
    80003a8c:	00000097          	auipc	ra,0x0
    80003a90:	b90080e7          	jalr	-1136(ra) # 8000361c <bread>
    80003a94:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a96:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a9a:	02049593          	slli	a1,s1,0x20
    80003a9e:	9181                	srli	a1,a1,0x20
    80003aa0:	058a                	slli	a1,a1,0x2
    80003aa2:	00b784b3          	add	s1,a5,a1
    80003aa6:	0004a903          	lw	s2,0(s1)
    80003aaa:	02090063          	beqz	s2,80003aca <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003aae:	8552                	mv	a0,s4
    80003ab0:	00000097          	auipc	ra,0x0
    80003ab4:	c9c080e7          	jalr	-868(ra) # 8000374c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003ab8:	854a                	mv	a0,s2
    80003aba:	70a2                	ld	ra,40(sp)
    80003abc:	7402                	ld	s0,32(sp)
    80003abe:	64e2                	ld	s1,24(sp)
    80003ac0:	6942                	ld	s2,16(sp)
    80003ac2:	69a2                	ld	s3,8(sp)
    80003ac4:	6a02                	ld	s4,0(sp)
    80003ac6:	6145                	addi	sp,sp,48
    80003ac8:	8082                	ret
      addr = balloc(ip->dev);
    80003aca:	0009a503          	lw	a0,0(s3)
    80003ace:	00000097          	auipc	ra,0x0
    80003ad2:	e10080e7          	jalr	-496(ra) # 800038de <balloc>
    80003ad6:	0005091b          	sext.w	s2,a0
      if(addr){
    80003ada:	fc090ae3          	beqz	s2,80003aae <bmap+0x98>
        a[bn] = addr;
    80003ade:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003ae2:	8552                	mv	a0,s4
    80003ae4:	00001097          	auipc	ra,0x1
    80003ae8:	eec080e7          	jalr	-276(ra) # 800049d0 <log_write>
    80003aec:	b7c9                	j	80003aae <bmap+0x98>
  panic("bmap: out of range");
    80003aee:	00005517          	auipc	a0,0x5
    80003af2:	a9250513          	addi	a0,a0,-1390 # 80008580 <syscalls+0x130>
    80003af6:	ffffd097          	auipc	ra,0xffffd
    80003afa:	a48080e7          	jalr	-1464(ra) # 8000053e <panic>

0000000080003afe <iget>:
{
    80003afe:	7179                	addi	sp,sp,-48
    80003b00:	f406                	sd	ra,40(sp)
    80003b02:	f022                	sd	s0,32(sp)
    80003b04:	ec26                	sd	s1,24(sp)
    80003b06:	e84a                	sd	s2,16(sp)
    80003b08:	e44e                	sd	s3,8(sp)
    80003b0a:	e052                	sd	s4,0(sp)
    80003b0c:	1800                	addi	s0,sp,48
    80003b0e:	89aa                	mv	s3,a0
    80003b10:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003b12:	0023c517          	auipc	a0,0x23c
    80003b16:	17e50513          	addi	a0,a0,382 # 8023fc90 <itable>
    80003b1a:	ffffd097          	auipc	ra,0xffffd
    80003b1e:	122080e7          	jalr	290(ra) # 80000c3c <acquire>
  empty = 0;
    80003b22:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b24:	0023c497          	auipc	s1,0x23c
    80003b28:	18448493          	addi	s1,s1,388 # 8023fca8 <itable+0x18>
    80003b2c:	0023e697          	auipc	a3,0x23e
    80003b30:	c0c68693          	addi	a3,a3,-1012 # 80241738 <log>
    80003b34:	a039                	j	80003b42 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b36:	02090b63          	beqz	s2,80003b6c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b3a:	08848493          	addi	s1,s1,136
    80003b3e:	02d48a63          	beq	s1,a3,80003b72 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b42:	449c                	lw	a5,8(s1)
    80003b44:	fef059e3          	blez	a5,80003b36 <iget+0x38>
    80003b48:	4098                	lw	a4,0(s1)
    80003b4a:	ff3716e3          	bne	a4,s3,80003b36 <iget+0x38>
    80003b4e:	40d8                	lw	a4,4(s1)
    80003b50:	ff4713e3          	bne	a4,s4,80003b36 <iget+0x38>
      ip->ref++;
    80003b54:	2785                	addiw	a5,a5,1
    80003b56:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b58:	0023c517          	auipc	a0,0x23c
    80003b5c:	13850513          	addi	a0,a0,312 # 8023fc90 <itable>
    80003b60:	ffffd097          	auipc	ra,0xffffd
    80003b64:	190080e7          	jalr	400(ra) # 80000cf0 <release>
      return ip;
    80003b68:	8926                	mv	s2,s1
    80003b6a:	a03d                	j	80003b98 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b6c:	f7f9                	bnez	a5,80003b3a <iget+0x3c>
    80003b6e:	8926                	mv	s2,s1
    80003b70:	b7e9                	j	80003b3a <iget+0x3c>
  if(empty == 0)
    80003b72:	02090c63          	beqz	s2,80003baa <iget+0xac>
  ip->dev = dev;
    80003b76:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b7a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b7e:	4785                	li	a5,1
    80003b80:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b84:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b88:	0023c517          	auipc	a0,0x23c
    80003b8c:	10850513          	addi	a0,a0,264 # 8023fc90 <itable>
    80003b90:	ffffd097          	auipc	ra,0xffffd
    80003b94:	160080e7          	jalr	352(ra) # 80000cf0 <release>
}
    80003b98:	854a                	mv	a0,s2
    80003b9a:	70a2                	ld	ra,40(sp)
    80003b9c:	7402                	ld	s0,32(sp)
    80003b9e:	64e2                	ld	s1,24(sp)
    80003ba0:	6942                	ld	s2,16(sp)
    80003ba2:	69a2                	ld	s3,8(sp)
    80003ba4:	6a02                	ld	s4,0(sp)
    80003ba6:	6145                	addi	sp,sp,48
    80003ba8:	8082                	ret
    panic("iget: no inodes");
    80003baa:	00005517          	auipc	a0,0x5
    80003bae:	9ee50513          	addi	a0,a0,-1554 # 80008598 <syscalls+0x148>
    80003bb2:	ffffd097          	auipc	ra,0xffffd
    80003bb6:	98c080e7          	jalr	-1652(ra) # 8000053e <panic>

0000000080003bba <fsinit>:
fsinit(int dev) {
    80003bba:	7179                	addi	sp,sp,-48
    80003bbc:	f406                	sd	ra,40(sp)
    80003bbe:	f022                	sd	s0,32(sp)
    80003bc0:	ec26                	sd	s1,24(sp)
    80003bc2:	e84a                	sd	s2,16(sp)
    80003bc4:	e44e                	sd	s3,8(sp)
    80003bc6:	1800                	addi	s0,sp,48
    80003bc8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003bca:	4585                	li	a1,1
    80003bcc:	00000097          	auipc	ra,0x0
    80003bd0:	a50080e7          	jalr	-1456(ra) # 8000361c <bread>
    80003bd4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003bd6:	0023c997          	auipc	s3,0x23c
    80003bda:	09a98993          	addi	s3,s3,154 # 8023fc70 <sb>
    80003bde:	02000613          	li	a2,32
    80003be2:	05850593          	addi	a1,a0,88
    80003be6:	854e                	mv	a0,s3
    80003be8:	ffffd097          	auipc	ra,0xffffd
    80003bec:	1ac080e7          	jalr	428(ra) # 80000d94 <memmove>
  brelse(bp);
    80003bf0:	8526                	mv	a0,s1
    80003bf2:	00000097          	auipc	ra,0x0
    80003bf6:	b5a080e7          	jalr	-1190(ra) # 8000374c <brelse>
  if(sb.magic != FSMAGIC)
    80003bfa:	0009a703          	lw	a4,0(s3)
    80003bfe:	102037b7          	lui	a5,0x10203
    80003c02:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c06:	02f71263          	bne	a4,a5,80003c2a <fsinit+0x70>
  initlog(dev, &sb);
    80003c0a:	0023c597          	auipc	a1,0x23c
    80003c0e:	06658593          	addi	a1,a1,102 # 8023fc70 <sb>
    80003c12:	854a                	mv	a0,s2
    80003c14:	00001097          	auipc	ra,0x1
    80003c18:	b40080e7          	jalr	-1216(ra) # 80004754 <initlog>
}
    80003c1c:	70a2                	ld	ra,40(sp)
    80003c1e:	7402                	ld	s0,32(sp)
    80003c20:	64e2                	ld	s1,24(sp)
    80003c22:	6942                	ld	s2,16(sp)
    80003c24:	69a2                	ld	s3,8(sp)
    80003c26:	6145                	addi	sp,sp,48
    80003c28:	8082                	ret
    panic("invalid file system");
    80003c2a:	00005517          	auipc	a0,0x5
    80003c2e:	97e50513          	addi	a0,a0,-1666 # 800085a8 <syscalls+0x158>
    80003c32:	ffffd097          	auipc	ra,0xffffd
    80003c36:	90c080e7          	jalr	-1780(ra) # 8000053e <panic>

0000000080003c3a <iinit>:
{
    80003c3a:	7179                	addi	sp,sp,-48
    80003c3c:	f406                	sd	ra,40(sp)
    80003c3e:	f022                	sd	s0,32(sp)
    80003c40:	ec26                	sd	s1,24(sp)
    80003c42:	e84a                	sd	s2,16(sp)
    80003c44:	e44e                	sd	s3,8(sp)
    80003c46:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c48:	00005597          	auipc	a1,0x5
    80003c4c:	97858593          	addi	a1,a1,-1672 # 800085c0 <syscalls+0x170>
    80003c50:	0023c517          	auipc	a0,0x23c
    80003c54:	04050513          	addi	a0,a0,64 # 8023fc90 <itable>
    80003c58:	ffffd097          	auipc	ra,0xffffd
    80003c5c:	f54080e7          	jalr	-172(ra) # 80000bac <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c60:	0023c497          	auipc	s1,0x23c
    80003c64:	05848493          	addi	s1,s1,88 # 8023fcb8 <itable+0x28>
    80003c68:	0023e997          	auipc	s3,0x23e
    80003c6c:	ae098993          	addi	s3,s3,-1312 # 80241748 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c70:	00005917          	auipc	s2,0x5
    80003c74:	95890913          	addi	s2,s2,-1704 # 800085c8 <syscalls+0x178>
    80003c78:	85ca                	mv	a1,s2
    80003c7a:	8526                	mv	a0,s1
    80003c7c:	00001097          	auipc	ra,0x1
    80003c80:	e3a080e7          	jalr	-454(ra) # 80004ab6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c84:	08848493          	addi	s1,s1,136
    80003c88:	ff3498e3          	bne	s1,s3,80003c78 <iinit+0x3e>
}
    80003c8c:	70a2                	ld	ra,40(sp)
    80003c8e:	7402                	ld	s0,32(sp)
    80003c90:	64e2                	ld	s1,24(sp)
    80003c92:	6942                	ld	s2,16(sp)
    80003c94:	69a2                	ld	s3,8(sp)
    80003c96:	6145                	addi	sp,sp,48
    80003c98:	8082                	ret

0000000080003c9a <ialloc>:
{
    80003c9a:	715d                	addi	sp,sp,-80
    80003c9c:	e486                	sd	ra,72(sp)
    80003c9e:	e0a2                	sd	s0,64(sp)
    80003ca0:	fc26                	sd	s1,56(sp)
    80003ca2:	f84a                	sd	s2,48(sp)
    80003ca4:	f44e                	sd	s3,40(sp)
    80003ca6:	f052                	sd	s4,32(sp)
    80003ca8:	ec56                	sd	s5,24(sp)
    80003caa:	e85a                	sd	s6,16(sp)
    80003cac:	e45e                	sd	s7,8(sp)
    80003cae:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cb0:	0023c717          	auipc	a4,0x23c
    80003cb4:	fcc72703          	lw	a4,-52(a4) # 8023fc7c <sb+0xc>
    80003cb8:	4785                	li	a5,1
    80003cba:	04e7fa63          	bgeu	a5,a4,80003d0e <ialloc+0x74>
    80003cbe:	8aaa                	mv	s5,a0
    80003cc0:	8bae                	mv	s7,a1
    80003cc2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003cc4:	0023ca17          	auipc	s4,0x23c
    80003cc8:	faca0a13          	addi	s4,s4,-84 # 8023fc70 <sb>
    80003ccc:	00048b1b          	sext.w	s6,s1
    80003cd0:	0044d793          	srli	a5,s1,0x4
    80003cd4:	018a2583          	lw	a1,24(s4)
    80003cd8:	9dbd                	addw	a1,a1,a5
    80003cda:	8556                	mv	a0,s5
    80003cdc:	00000097          	auipc	ra,0x0
    80003ce0:	940080e7          	jalr	-1728(ra) # 8000361c <bread>
    80003ce4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ce6:	05850993          	addi	s3,a0,88
    80003cea:	00f4f793          	andi	a5,s1,15
    80003cee:	079a                	slli	a5,a5,0x6
    80003cf0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003cf2:	00099783          	lh	a5,0(s3)
    80003cf6:	c3a1                	beqz	a5,80003d36 <ialloc+0x9c>
    brelse(bp);
    80003cf8:	00000097          	auipc	ra,0x0
    80003cfc:	a54080e7          	jalr	-1452(ra) # 8000374c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d00:	0485                	addi	s1,s1,1
    80003d02:	00ca2703          	lw	a4,12(s4)
    80003d06:	0004879b          	sext.w	a5,s1
    80003d0a:	fce7e1e3          	bltu	a5,a4,80003ccc <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003d0e:	00005517          	auipc	a0,0x5
    80003d12:	8c250513          	addi	a0,a0,-1854 # 800085d0 <syscalls+0x180>
    80003d16:	ffffd097          	auipc	ra,0xffffd
    80003d1a:	872080e7          	jalr	-1934(ra) # 80000588 <printf>
  return 0;
    80003d1e:	4501                	li	a0,0
}
    80003d20:	60a6                	ld	ra,72(sp)
    80003d22:	6406                	ld	s0,64(sp)
    80003d24:	74e2                	ld	s1,56(sp)
    80003d26:	7942                	ld	s2,48(sp)
    80003d28:	79a2                	ld	s3,40(sp)
    80003d2a:	7a02                	ld	s4,32(sp)
    80003d2c:	6ae2                	ld	s5,24(sp)
    80003d2e:	6b42                	ld	s6,16(sp)
    80003d30:	6ba2                	ld	s7,8(sp)
    80003d32:	6161                	addi	sp,sp,80
    80003d34:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003d36:	04000613          	li	a2,64
    80003d3a:	4581                	li	a1,0
    80003d3c:	854e                	mv	a0,s3
    80003d3e:	ffffd097          	auipc	ra,0xffffd
    80003d42:	ffa080e7          	jalr	-6(ra) # 80000d38 <memset>
      dip->type = type;
    80003d46:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d4a:	854a                	mv	a0,s2
    80003d4c:	00001097          	auipc	ra,0x1
    80003d50:	c84080e7          	jalr	-892(ra) # 800049d0 <log_write>
      brelse(bp);
    80003d54:	854a                	mv	a0,s2
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	9f6080e7          	jalr	-1546(ra) # 8000374c <brelse>
      return iget(dev, inum);
    80003d5e:	85da                	mv	a1,s6
    80003d60:	8556                	mv	a0,s5
    80003d62:	00000097          	auipc	ra,0x0
    80003d66:	d9c080e7          	jalr	-612(ra) # 80003afe <iget>
    80003d6a:	bf5d                	j	80003d20 <ialloc+0x86>

0000000080003d6c <iupdate>:
{
    80003d6c:	1101                	addi	sp,sp,-32
    80003d6e:	ec06                	sd	ra,24(sp)
    80003d70:	e822                	sd	s0,16(sp)
    80003d72:	e426                	sd	s1,8(sp)
    80003d74:	e04a                	sd	s2,0(sp)
    80003d76:	1000                	addi	s0,sp,32
    80003d78:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d7a:	415c                	lw	a5,4(a0)
    80003d7c:	0047d79b          	srliw	a5,a5,0x4
    80003d80:	0023c597          	auipc	a1,0x23c
    80003d84:	f085a583          	lw	a1,-248(a1) # 8023fc88 <sb+0x18>
    80003d88:	9dbd                	addw	a1,a1,a5
    80003d8a:	4108                	lw	a0,0(a0)
    80003d8c:	00000097          	auipc	ra,0x0
    80003d90:	890080e7          	jalr	-1904(ra) # 8000361c <bread>
    80003d94:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d96:	05850793          	addi	a5,a0,88
    80003d9a:	40c8                	lw	a0,4(s1)
    80003d9c:	893d                	andi	a0,a0,15
    80003d9e:	051a                	slli	a0,a0,0x6
    80003da0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003da2:	04449703          	lh	a4,68(s1)
    80003da6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003daa:	04649703          	lh	a4,70(s1)
    80003dae:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003db2:	04849703          	lh	a4,72(s1)
    80003db6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003dba:	04a49703          	lh	a4,74(s1)
    80003dbe:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003dc2:	44f8                	lw	a4,76(s1)
    80003dc4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003dc6:	03400613          	li	a2,52
    80003dca:	05048593          	addi	a1,s1,80
    80003dce:	0531                	addi	a0,a0,12
    80003dd0:	ffffd097          	auipc	ra,0xffffd
    80003dd4:	fc4080e7          	jalr	-60(ra) # 80000d94 <memmove>
  log_write(bp);
    80003dd8:	854a                	mv	a0,s2
    80003dda:	00001097          	auipc	ra,0x1
    80003dde:	bf6080e7          	jalr	-1034(ra) # 800049d0 <log_write>
  brelse(bp);
    80003de2:	854a                	mv	a0,s2
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	968080e7          	jalr	-1688(ra) # 8000374c <brelse>
}
    80003dec:	60e2                	ld	ra,24(sp)
    80003dee:	6442                	ld	s0,16(sp)
    80003df0:	64a2                	ld	s1,8(sp)
    80003df2:	6902                	ld	s2,0(sp)
    80003df4:	6105                	addi	sp,sp,32
    80003df6:	8082                	ret

0000000080003df8 <idup>:
{
    80003df8:	1101                	addi	sp,sp,-32
    80003dfa:	ec06                	sd	ra,24(sp)
    80003dfc:	e822                	sd	s0,16(sp)
    80003dfe:	e426                	sd	s1,8(sp)
    80003e00:	1000                	addi	s0,sp,32
    80003e02:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e04:	0023c517          	auipc	a0,0x23c
    80003e08:	e8c50513          	addi	a0,a0,-372 # 8023fc90 <itable>
    80003e0c:	ffffd097          	auipc	ra,0xffffd
    80003e10:	e30080e7          	jalr	-464(ra) # 80000c3c <acquire>
  ip->ref++;
    80003e14:	449c                	lw	a5,8(s1)
    80003e16:	2785                	addiw	a5,a5,1
    80003e18:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e1a:	0023c517          	auipc	a0,0x23c
    80003e1e:	e7650513          	addi	a0,a0,-394 # 8023fc90 <itable>
    80003e22:	ffffd097          	auipc	ra,0xffffd
    80003e26:	ece080e7          	jalr	-306(ra) # 80000cf0 <release>
}
    80003e2a:	8526                	mv	a0,s1
    80003e2c:	60e2                	ld	ra,24(sp)
    80003e2e:	6442                	ld	s0,16(sp)
    80003e30:	64a2                	ld	s1,8(sp)
    80003e32:	6105                	addi	sp,sp,32
    80003e34:	8082                	ret

0000000080003e36 <ilock>:
{
    80003e36:	1101                	addi	sp,sp,-32
    80003e38:	ec06                	sd	ra,24(sp)
    80003e3a:	e822                	sd	s0,16(sp)
    80003e3c:	e426                	sd	s1,8(sp)
    80003e3e:	e04a                	sd	s2,0(sp)
    80003e40:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e42:	c115                	beqz	a0,80003e66 <ilock+0x30>
    80003e44:	84aa                	mv	s1,a0
    80003e46:	451c                	lw	a5,8(a0)
    80003e48:	00f05f63          	blez	a5,80003e66 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e4c:	0541                	addi	a0,a0,16
    80003e4e:	00001097          	auipc	ra,0x1
    80003e52:	ca2080e7          	jalr	-862(ra) # 80004af0 <acquiresleep>
  if(ip->valid == 0){
    80003e56:	40bc                	lw	a5,64(s1)
    80003e58:	cf99                	beqz	a5,80003e76 <ilock+0x40>
}
    80003e5a:	60e2                	ld	ra,24(sp)
    80003e5c:	6442                	ld	s0,16(sp)
    80003e5e:	64a2                	ld	s1,8(sp)
    80003e60:	6902                	ld	s2,0(sp)
    80003e62:	6105                	addi	sp,sp,32
    80003e64:	8082                	ret
    panic("ilock");
    80003e66:	00004517          	auipc	a0,0x4
    80003e6a:	78250513          	addi	a0,a0,1922 # 800085e8 <syscalls+0x198>
    80003e6e:	ffffc097          	auipc	ra,0xffffc
    80003e72:	6d0080e7          	jalr	1744(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e76:	40dc                	lw	a5,4(s1)
    80003e78:	0047d79b          	srliw	a5,a5,0x4
    80003e7c:	0023c597          	auipc	a1,0x23c
    80003e80:	e0c5a583          	lw	a1,-500(a1) # 8023fc88 <sb+0x18>
    80003e84:	9dbd                	addw	a1,a1,a5
    80003e86:	4088                	lw	a0,0(s1)
    80003e88:	fffff097          	auipc	ra,0xfffff
    80003e8c:	794080e7          	jalr	1940(ra) # 8000361c <bread>
    80003e90:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e92:	05850593          	addi	a1,a0,88
    80003e96:	40dc                	lw	a5,4(s1)
    80003e98:	8bbd                	andi	a5,a5,15
    80003e9a:	079a                	slli	a5,a5,0x6
    80003e9c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e9e:	00059783          	lh	a5,0(a1)
    80003ea2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ea6:	00259783          	lh	a5,2(a1)
    80003eaa:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003eae:	00459783          	lh	a5,4(a1)
    80003eb2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003eb6:	00659783          	lh	a5,6(a1)
    80003eba:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ebe:	459c                	lw	a5,8(a1)
    80003ec0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ec2:	03400613          	li	a2,52
    80003ec6:	05b1                	addi	a1,a1,12
    80003ec8:	05048513          	addi	a0,s1,80
    80003ecc:	ffffd097          	auipc	ra,0xffffd
    80003ed0:	ec8080e7          	jalr	-312(ra) # 80000d94 <memmove>
    brelse(bp);
    80003ed4:	854a                	mv	a0,s2
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	876080e7          	jalr	-1930(ra) # 8000374c <brelse>
    ip->valid = 1;
    80003ede:	4785                	li	a5,1
    80003ee0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ee2:	04449783          	lh	a5,68(s1)
    80003ee6:	fbb5                	bnez	a5,80003e5a <ilock+0x24>
      panic("ilock: no type");
    80003ee8:	00004517          	auipc	a0,0x4
    80003eec:	70850513          	addi	a0,a0,1800 # 800085f0 <syscalls+0x1a0>
    80003ef0:	ffffc097          	auipc	ra,0xffffc
    80003ef4:	64e080e7          	jalr	1614(ra) # 8000053e <panic>

0000000080003ef8 <iunlock>:
{
    80003ef8:	1101                	addi	sp,sp,-32
    80003efa:	ec06                	sd	ra,24(sp)
    80003efc:	e822                	sd	s0,16(sp)
    80003efe:	e426                	sd	s1,8(sp)
    80003f00:	e04a                	sd	s2,0(sp)
    80003f02:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f04:	c905                	beqz	a0,80003f34 <iunlock+0x3c>
    80003f06:	84aa                	mv	s1,a0
    80003f08:	01050913          	addi	s2,a0,16
    80003f0c:	854a                	mv	a0,s2
    80003f0e:	00001097          	auipc	ra,0x1
    80003f12:	c7c080e7          	jalr	-900(ra) # 80004b8a <holdingsleep>
    80003f16:	cd19                	beqz	a0,80003f34 <iunlock+0x3c>
    80003f18:	449c                	lw	a5,8(s1)
    80003f1a:	00f05d63          	blez	a5,80003f34 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f1e:	854a                	mv	a0,s2
    80003f20:	00001097          	auipc	ra,0x1
    80003f24:	c26080e7          	jalr	-986(ra) # 80004b46 <releasesleep>
}
    80003f28:	60e2                	ld	ra,24(sp)
    80003f2a:	6442                	ld	s0,16(sp)
    80003f2c:	64a2                	ld	s1,8(sp)
    80003f2e:	6902                	ld	s2,0(sp)
    80003f30:	6105                	addi	sp,sp,32
    80003f32:	8082                	ret
    panic("iunlock");
    80003f34:	00004517          	auipc	a0,0x4
    80003f38:	6cc50513          	addi	a0,a0,1740 # 80008600 <syscalls+0x1b0>
    80003f3c:	ffffc097          	auipc	ra,0xffffc
    80003f40:	602080e7          	jalr	1538(ra) # 8000053e <panic>

0000000080003f44 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f44:	7179                	addi	sp,sp,-48
    80003f46:	f406                	sd	ra,40(sp)
    80003f48:	f022                	sd	s0,32(sp)
    80003f4a:	ec26                	sd	s1,24(sp)
    80003f4c:	e84a                	sd	s2,16(sp)
    80003f4e:	e44e                	sd	s3,8(sp)
    80003f50:	e052                	sd	s4,0(sp)
    80003f52:	1800                	addi	s0,sp,48
    80003f54:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f56:	05050493          	addi	s1,a0,80
    80003f5a:	08050913          	addi	s2,a0,128
    80003f5e:	a021                	j	80003f66 <itrunc+0x22>
    80003f60:	0491                	addi	s1,s1,4
    80003f62:	01248d63          	beq	s1,s2,80003f7c <itrunc+0x38>
    if(ip->addrs[i]){
    80003f66:	408c                	lw	a1,0(s1)
    80003f68:	dde5                	beqz	a1,80003f60 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f6a:	0009a503          	lw	a0,0(s3)
    80003f6e:	00000097          	auipc	ra,0x0
    80003f72:	8f4080e7          	jalr	-1804(ra) # 80003862 <bfree>
      ip->addrs[i] = 0;
    80003f76:	0004a023          	sw	zero,0(s1)
    80003f7a:	b7dd                	j	80003f60 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f7c:	0809a583          	lw	a1,128(s3)
    80003f80:	e185                	bnez	a1,80003fa0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f82:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f86:	854e                	mv	a0,s3
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	de4080e7          	jalr	-540(ra) # 80003d6c <iupdate>
}
    80003f90:	70a2                	ld	ra,40(sp)
    80003f92:	7402                	ld	s0,32(sp)
    80003f94:	64e2                	ld	s1,24(sp)
    80003f96:	6942                	ld	s2,16(sp)
    80003f98:	69a2                	ld	s3,8(sp)
    80003f9a:	6a02                	ld	s4,0(sp)
    80003f9c:	6145                	addi	sp,sp,48
    80003f9e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003fa0:	0009a503          	lw	a0,0(s3)
    80003fa4:	fffff097          	auipc	ra,0xfffff
    80003fa8:	678080e7          	jalr	1656(ra) # 8000361c <bread>
    80003fac:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003fae:	05850493          	addi	s1,a0,88
    80003fb2:	45850913          	addi	s2,a0,1112
    80003fb6:	a021                	j	80003fbe <itrunc+0x7a>
    80003fb8:	0491                	addi	s1,s1,4
    80003fba:	01248b63          	beq	s1,s2,80003fd0 <itrunc+0x8c>
      if(a[j])
    80003fbe:	408c                	lw	a1,0(s1)
    80003fc0:	dde5                	beqz	a1,80003fb8 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003fc2:	0009a503          	lw	a0,0(s3)
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	89c080e7          	jalr	-1892(ra) # 80003862 <bfree>
    80003fce:	b7ed                	j	80003fb8 <itrunc+0x74>
    brelse(bp);
    80003fd0:	8552                	mv	a0,s4
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	77a080e7          	jalr	1914(ra) # 8000374c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003fda:	0809a583          	lw	a1,128(s3)
    80003fde:	0009a503          	lw	a0,0(s3)
    80003fe2:	00000097          	auipc	ra,0x0
    80003fe6:	880080e7          	jalr	-1920(ra) # 80003862 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003fea:	0809a023          	sw	zero,128(s3)
    80003fee:	bf51                	j	80003f82 <itrunc+0x3e>

0000000080003ff0 <iput>:
{
    80003ff0:	1101                	addi	sp,sp,-32
    80003ff2:	ec06                	sd	ra,24(sp)
    80003ff4:	e822                	sd	s0,16(sp)
    80003ff6:	e426                	sd	s1,8(sp)
    80003ff8:	e04a                	sd	s2,0(sp)
    80003ffa:	1000                	addi	s0,sp,32
    80003ffc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ffe:	0023c517          	auipc	a0,0x23c
    80004002:	c9250513          	addi	a0,a0,-878 # 8023fc90 <itable>
    80004006:	ffffd097          	auipc	ra,0xffffd
    8000400a:	c36080e7          	jalr	-970(ra) # 80000c3c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000400e:	4498                	lw	a4,8(s1)
    80004010:	4785                	li	a5,1
    80004012:	02f70363          	beq	a4,a5,80004038 <iput+0x48>
  ip->ref--;
    80004016:	449c                	lw	a5,8(s1)
    80004018:	37fd                	addiw	a5,a5,-1
    8000401a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000401c:	0023c517          	auipc	a0,0x23c
    80004020:	c7450513          	addi	a0,a0,-908 # 8023fc90 <itable>
    80004024:	ffffd097          	auipc	ra,0xffffd
    80004028:	ccc080e7          	jalr	-820(ra) # 80000cf0 <release>
}
    8000402c:	60e2                	ld	ra,24(sp)
    8000402e:	6442                	ld	s0,16(sp)
    80004030:	64a2                	ld	s1,8(sp)
    80004032:	6902                	ld	s2,0(sp)
    80004034:	6105                	addi	sp,sp,32
    80004036:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004038:	40bc                	lw	a5,64(s1)
    8000403a:	dff1                	beqz	a5,80004016 <iput+0x26>
    8000403c:	04a49783          	lh	a5,74(s1)
    80004040:	fbf9                	bnez	a5,80004016 <iput+0x26>
    acquiresleep(&ip->lock);
    80004042:	01048913          	addi	s2,s1,16
    80004046:	854a                	mv	a0,s2
    80004048:	00001097          	auipc	ra,0x1
    8000404c:	aa8080e7          	jalr	-1368(ra) # 80004af0 <acquiresleep>
    release(&itable.lock);
    80004050:	0023c517          	auipc	a0,0x23c
    80004054:	c4050513          	addi	a0,a0,-960 # 8023fc90 <itable>
    80004058:	ffffd097          	auipc	ra,0xffffd
    8000405c:	c98080e7          	jalr	-872(ra) # 80000cf0 <release>
    itrunc(ip);
    80004060:	8526                	mv	a0,s1
    80004062:	00000097          	auipc	ra,0x0
    80004066:	ee2080e7          	jalr	-286(ra) # 80003f44 <itrunc>
    ip->type = 0;
    8000406a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000406e:	8526                	mv	a0,s1
    80004070:	00000097          	auipc	ra,0x0
    80004074:	cfc080e7          	jalr	-772(ra) # 80003d6c <iupdate>
    ip->valid = 0;
    80004078:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000407c:	854a                	mv	a0,s2
    8000407e:	00001097          	auipc	ra,0x1
    80004082:	ac8080e7          	jalr	-1336(ra) # 80004b46 <releasesleep>
    acquire(&itable.lock);
    80004086:	0023c517          	auipc	a0,0x23c
    8000408a:	c0a50513          	addi	a0,a0,-1014 # 8023fc90 <itable>
    8000408e:	ffffd097          	auipc	ra,0xffffd
    80004092:	bae080e7          	jalr	-1106(ra) # 80000c3c <acquire>
    80004096:	b741                	j	80004016 <iput+0x26>

0000000080004098 <iunlockput>:
{
    80004098:	1101                	addi	sp,sp,-32
    8000409a:	ec06                	sd	ra,24(sp)
    8000409c:	e822                	sd	s0,16(sp)
    8000409e:	e426                	sd	s1,8(sp)
    800040a0:	1000                	addi	s0,sp,32
    800040a2:	84aa                	mv	s1,a0
  iunlock(ip);
    800040a4:	00000097          	auipc	ra,0x0
    800040a8:	e54080e7          	jalr	-428(ra) # 80003ef8 <iunlock>
  iput(ip);
    800040ac:	8526                	mv	a0,s1
    800040ae:	00000097          	auipc	ra,0x0
    800040b2:	f42080e7          	jalr	-190(ra) # 80003ff0 <iput>
}
    800040b6:	60e2                	ld	ra,24(sp)
    800040b8:	6442                	ld	s0,16(sp)
    800040ba:	64a2                	ld	s1,8(sp)
    800040bc:	6105                	addi	sp,sp,32
    800040be:	8082                	ret

00000000800040c0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800040c0:	1141                	addi	sp,sp,-16
    800040c2:	e422                	sd	s0,8(sp)
    800040c4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800040c6:	411c                	lw	a5,0(a0)
    800040c8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800040ca:	415c                	lw	a5,4(a0)
    800040cc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800040ce:	04451783          	lh	a5,68(a0)
    800040d2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800040d6:	04a51783          	lh	a5,74(a0)
    800040da:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800040de:	04c56783          	lwu	a5,76(a0)
    800040e2:	e99c                	sd	a5,16(a1)
}
    800040e4:	6422                	ld	s0,8(sp)
    800040e6:	0141                	addi	sp,sp,16
    800040e8:	8082                	ret

00000000800040ea <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040ea:	457c                	lw	a5,76(a0)
    800040ec:	0ed7e963          	bltu	a5,a3,800041de <readi+0xf4>
{
    800040f0:	7159                	addi	sp,sp,-112
    800040f2:	f486                	sd	ra,104(sp)
    800040f4:	f0a2                	sd	s0,96(sp)
    800040f6:	eca6                	sd	s1,88(sp)
    800040f8:	e8ca                	sd	s2,80(sp)
    800040fa:	e4ce                	sd	s3,72(sp)
    800040fc:	e0d2                	sd	s4,64(sp)
    800040fe:	fc56                	sd	s5,56(sp)
    80004100:	f85a                	sd	s6,48(sp)
    80004102:	f45e                	sd	s7,40(sp)
    80004104:	f062                	sd	s8,32(sp)
    80004106:	ec66                	sd	s9,24(sp)
    80004108:	e86a                	sd	s10,16(sp)
    8000410a:	e46e                	sd	s11,8(sp)
    8000410c:	1880                	addi	s0,sp,112
    8000410e:	8b2a                	mv	s6,a0
    80004110:	8bae                	mv	s7,a1
    80004112:	8a32                	mv	s4,a2
    80004114:	84b6                	mv	s1,a3
    80004116:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004118:	9f35                	addw	a4,a4,a3
    return 0;
    8000411a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000411c:	0ad76063          	bltu	a4,a3,800041bc <readi+0xd2>
  if(off + n > ip->size)
    80004120:	00e7f463          	bgeu	a5,a4,80004128 <readi+0x3e>
    n = ip->size - off;
    80004124:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004128:	0a0a8963          	beqz	s5,800041da <readi+0xf0>
    8000412c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000412e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004132:	5c7d                	li	s8,-1
    80004134:	a82d                	j	8000416e <readi+0x84>
    80004136:	020d1d93          	slli	s11,s10,0x20
    8000413a:	020ddd93          	srli	s11,s11,0x20
    8000413e:	05890793          	addi	a5,s2,88
    80004142:	86ee                	mv	a3,s11
    80004144:	963e                	add	a2,a2,a5
    80004146:	85d2                	mv	a1,s4
    80004148:	855e                	mv	a0,s7
    8000414a:	ffffe097          	auipc	ra,0xffffe
    8000414e:	7bc080e7          	jalr	1980(ra) # 80002906 <either_copyout>
    80004152:	05850d63          	beq	a0,s8,800041ac <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004156:	854a                	mv	a0,s2
    80004158:	fffff097          	auipc	ra,0xfffff
    8000415c:	5f4080e7          	jalr	1524(ra) # 8000374c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004160:	013d09bb          	addw	s3,s10,s3
    80004164:	009d04bb          	addw	s1,s10,s1
    80004168:	9a6e                	add	s4,s4,s11
    8000416a:	0559f763          	bgeu	s3,s5,800041b8 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000416e:	00a4d59b          	srliw	a1,s1,0xa
    80004172:	855a                	mv	a0,s6
    80004174:	00000097          	auipc	ra,0x0
    80004178:	8a2080e7          	jalr	-1886(ra) # 80003a16 <bmap>
    8000417c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004180:	cd85                	beqz	a1,800041b8 <readi+0xce>
    bp = bread(ip->dev, addr);
    80004182:	000b2503          	lw	a0,0(s6)
    80004186:	fffff097          	auipc	ra,0xfffff
    8000418a:	496080e7          	jalr	1174(ra) # 8000361c <bread>
    8000418e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004190:	3ff4f613          	andi	a2,s1,1023
    80004194:	40cc87bb          	subw	a5,s9,a2
    80004198:	413a873b          	subw	a4,s5,s3
    8000419c:	8d3e                	mv	s10,a5
    8000419e:	2781                	sext.w	a5,a5
    800041a0:	0007069b          	sext.w	a3,a4
    800041a4:	f8f6f9e3          	bgeu	a3,a5,80004136 <readi+0x4c>
    800041a8:	8d3a                	mv	s10,a4
    800041aa:	b771                	j	80004136 <readi+0x4c>
      brelse(bp);
    800041ac:	854a                	mv	a0,s2
    800041ae:	fffff097          	auipc	ra,0xfffff
    800041b2:	59e080e7          	jalr	1438(ra) # 8000374c <brelse>
      tot = -1;
    800041b6:	59fd                	li	s3,-1
  }
  return tot;
    800041b8:	0009851b          	sext.w	a0,s3
}
    800041bc:	70a6                	ld	ra,104(sp)
    800041be:	7406                	ld	s0,96(sp)
    800041c0:	64e6                	ld	s1,88(sp)
    800041c2:	6946                	ld	s2,80(sp)
    800041c4:	69a6                	ld	s3,72(sp)
    800041c6:	6a06                	ld	s4,64(sp)
    800041c8:	7ae2                	ld	s5,56(sp)
    800041ca:	7b42                	ld	s6,48(sp)
    800041cc:	7ba2                	ld	s7,40(sp)
    800041ce:	7c02                	ld	s8,32(sp)
    800041d0:	6ce2                	ld	s9,24(sp)
    800041d2:	6d42                	ld	s10,16(sp)
    800041d4:	6da2                	ld	s11,8(sp)
    800041d6:	6165                	addi	sp,sp,112
    800041d8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041da:	89d6                	mv	s3,s5
    800041dc:	bff1                	j	800041b8 <readi+0xce>
    return 0;
    800041de:	4501                	li	a0,0
}
    800041e0:	8082                	ret

00000000800041e2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041e2:	457c                	lw	a5,76(a0)
    800041e4:	10d7e863          	bltu	a5,a3,800042f4 <writei+0x112>
{
    800041e8:	7159                	addi	sp,sp,-112
    800041ea:	f486                	sd	ra,104(sp)
    800041ec:	f0a2                	sd	s0,96(sp)
    800041ee:	eca6                	sd	s1,88(sp)
    800041f0:	e8ca                	sd	s2,80(sp)
    800041f2:	e4ce                	sd	s3,72(sp)
    800041f4:	e0d2                	sd	s4,64(sp)
    800041f6:	fc56                	sd	s5,56(sp)
    800041f8:	f85a                	sd	s6,48(sp)
    800041fa:	f45e                	sd	s7,40(sp)
    800041fc:	f062                	sd	s8,32(sp)
    800041fe:	ec66                	sd	s9,24(sp)
    80004200:	e86a                	sd	s10,16(sp)
    80004202:	e46e                	sd	s11,8(sp)
    80004204:	1880                	addi	s0,sp,112
    80004206:	8aaa                	mv	s5,a0
    80004208:	8bae                	mv	s7,a1
    8000420a:	8a32                	mv	s4,a2
    8000420c:	8936                	mv	s2,a3
    8000420e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004210:	00e687bb          	addw	a5,a3,a4
    80004214:	0ed7e263          	bltu	a5,a3,800042f8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004218:	00043737          	lui	a4,0x43
    8000421c:	0ef76063          	bltu	a4,a5,800042fc <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004220:	0c0b0863          	beqz	s6,800042f0 <writei+0x10e>
    80004224:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004226:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000422a:	5c7d                	li	s8,-1
    8000422c:	a091                	j	80004270 <writei+0x8e>
    8000422e:	020d1d93          	slli	s11,s10,0x20
    80004232:	020ddd93          	srli	s11,s11,0x20
    80004236:	05848793          	addi	a5,s1,88
    8000423a:	86ee                	mv	a3,s11
    8000423c:	8652                	mv	a2,s4
    8000423e:	85de                	mv	a1,s7
    80004240:	953e                	add	a0,a0,a5
    80004242:	ffffe097          	auipc	ra,0xffffe
    80004246:	71a080e7          	jalr	1818(ra) # 8000295c <either_copyin>
    8000424a:	07850263          	beq	a0,s8,800042ae <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000424e:	8526                	mv	a0,s1
    80004250:	00000097          	auipc	ra,0x0
    80004254:	780080e7          	jalr	1920(ra) # 800049d0 <log_write>
    brelse(bp);
    80004258:	8526                	mv	a0,s1
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	4f2080e7          	jalr	1266(ra) # 8000374c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004262:	013d09bb          	addw	s3,s10,s3
    80004266:	012d093b          	addw	s2,s10,s2
    8000426a:	9a6e                	add	s4,s4,s11
    8000426c:	0569f663          	bgeu	s3,s6,800042b8 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004270:	00a9559b          	srliw	a1,s2,0xa
    80004274:	8556                	mv	a0,s5
    80004276:	fffff097          	auipc	ra,0xfffff
    8000427a:	7a0080e7          	jalr	1952(ra) # 80003a16 <bmap>
    8000427e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004282:	c99d                	beqz	a1,800042b8 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004284:	000aa503          	lw	a0,0(s5)
    80004288:	fffff097          	auipc	ra,0xfffff
    8000428c:	394080e7          	jalr	916(ra) # 8000361c <bread>
    80004290:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004292:	3ff97513          	andi	a0,s2,1023
    80004296:	40ac87bb          	subw	a5,s9,a0
    8000429a:	413b073b          	subw	a4,s6,s3
    8000429e:	8d3e                	mv	s10,a5
    800042a0:	2781                	sext.w	a5,a5
    800042a2:	0007069b          	sext.w	a3,a4
    800042a6:	f8f6f4e3          	bgeu	a3,a5,8000422e <writei+0x4c>
    800042aa:	8d3a                	mv	s10,a4
    800042ac:	b749                	j	8000422e <writei+0x4c>
      brelse(bp);
    800042ae:	8526                	mv	a0,s1
    800042b0:	fffff097          	auipc	ra,0xfffff
    800042b4:	49c080e7          	jalr	1180(ra) # 8000374c <brelse>
  }

  if(off > ip->size)
    800042b8:	04caa783          	lw	a5,76(s5)
    800042bc:	0127f463          	bgeu	a5,s2,800042c4 <writei+0xe2>
    ip->size = off;
    800042c0:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800042c4:	8556                	mv	a0,s5
    800042c6:	00000097          	auipc	ra,0x0
    800042ca:	aa6080e7          	jalr	-1370(ra) # 80003d6c <iupdate>

  return tot;
    800042ce:	0009851b          	sext.w	a0,s3
}
    800042d2:	70a6                	ld	ra,104(sp)
    800042d4:	7406                	ld	s0,96(sp)
    800042d6:	64e6                	ld	s1,88(sp)
    800042d8:	6946                	ld	s2,80(sp)
    800042da:	69a6                	ld	s3,72(sp)
    800042dc:	6a06                	ld	s4,64(sp)
    800042de:	7ae2                	ld	s5,56(sp)
    800042e0:	7b42                	ld	s6,48(sp)
    800042e2:	7ba2                	ld	s7,40(sp)
    800042e4:	7c02                	ld	s8,32(sp)
    800042e6:	6ce2                	ld	s9,24(sp)
    800042e8:	6d42                	ld	s10,16(sp)
    800042ea:	6da2                	ld	s11,8(sp)
    800042ec:	6165                	addi	sp,sp,112
    800042ee:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042f0:	89da                	mv	s3,s6
    800042f2:	bfc9                	j	800042c4 <writei+0xe2>
    return -1;
    800042f4:	557d                	li	a0,-1
}
    800042f6:	8082                	ret
    return -1;
    800042f8:	557d                	li	a0,-1
    800042fa:	bfe1                	j	800042d2 <writei+0xf0>
    return -1;
    800042fc:	557d                	li	a0,-1
    800042fe:	bfd1                	j	800042d2 <writei+0xf0>

0000000080004300 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004300:	1141                	addi	sp,sp,-16
    80004302:	e406                	sd	ra,8(sp)
    80004304:	e022                	sd	s0,0(sp)
    80004306:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004308:	4639                	li	a2,14
    8000430a:	ffffd097          	auipc	ra,0xffffd
    8000430e:	afe080e7          	jalr	-1282(ra) # 80000e08 <strncmp>
}
    80004312:	60a2                	ld	ra,8(sp)
    80004314:	6402                	ld	s0,0(sp)
    80004316:	0141                	addi	sp,sp,16
    80004318:	8082                	ret

000000008000431a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000431a:	7139                	addi	sp,sp,-64
    8000431c:	fc06                	sd	ra,56(sp)
    8000431e:	f822                	sd	s0,48(sp)
    80004320:	f426                	sd	s1,40(sp)
    80004322:	f04a                	sd	s2,32(sp)
    80004324:	ec4e                	sd	s3,24(sp)
    80004326:	e852                	sd	s4,16(sp)
    80004328:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000432a:	04451703          	lh	a4,68(a0)
    8000432e:	4785                	li	a5,1
    80004330:	00f71a63          	bne	a4,a5,80004344 <dirlookup+0x2a>
    80004334:	892a                	mv	s2,a0
    80004336:	89ae                	mv	s3,a1
    80004338:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000433a:	457c                	lw	a5,76(a0)
    8000433c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000433e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004340:	e79d                	bnez	a5,8000436e <dirlookup+0x54>
    80004342:	a8a5                	j	800043ba <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004344:	00004517          	auipc	a0,0x4
    80004348:	2c450513          	addi	a0,a0,708 # 80008608 <syscalls+0x1b8>
    8000434c:	ffffc097          	auipc	ra,0xffffc
    80004350:	1f2080e7          	jalr	498(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004354:	00004517          	auipc	a0,0x4
    80004358:	2cc50513          	addi	a0,a0,716 # 80008620 <syscalls+0x1d0>
    8000435c:	ffffc097          	auipc	ra,0xffffc
    80004360:	1e2080e7          	jalr	482(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004364:	24c1                	addiw	s1,s1,16
    80004366:	04c92783          	lw	a5,76(s2)
    8000436a:	04f4f763          	bgeu	s1,a5,800043b8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000436e:	4741                	li	a4,16
    80004370:	86a6                	mv	a3,s1
    80004372:	fc040613          	addi	a2,s0,-64
    80004376:	4581                	li	a1,0
    80004378:	854a                	mv	a0,s2
    8000437a:	00000097          	auipc	ra,0x0
    8000437e:	d70080e7          	jalr	-656(ra) # 800040ea <readi>
    80004382:	47c1                	li	a5,16
    80004384:	fcf518e3          	bne	a0,a5,80004354 <dirlookup+0x3a>
    if(de.inum == 0)
    80004388:	fc045783          	lhu	a5,-64(s0)
    8000438c:	dfe1                	beqz	a5,80004364 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000438e:	fc240593          	addi	a1,s0,-62
    80004392:	854e                	mv	a0,s3
    80004394:	00000097          	auipc	ra,0x0
    80004398:	f6c080e7          	jalr	-148(ra) # 80004300 <namecmp>
    8000439c:	f561                	bnez	a0,80004364 <dirlookup+0x4a>
      if(poff)
    8000439e:	000a0463          	beqz	s4,800043a6 <dirlookup+0x8c>
        *poff = off;
    800043a2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800043a6:	fc045583          	lhu	a1,-64(s0)
    800043aa:	00092503          	lw	a0,0(s2)
    800043ae:	fffff097          	auipc	ra,0xfffff
    800043b2:	750080e7          	jalr	1872(ra) # 80003afe <iget>
    800043b6:	a011                	j	800043ba <dirlookup+0xa0>
  return 0;
    800043b8:	4501                	li	a0,0
}
    800043ba:	70e2                	ld	ra,56(sp)
    800043bc:	7442                	ld	s0,48(sp)
    800043be:	74a2                	ld	s1,40(sp)
    800043c0:	7902                	ld	s2,32(sp)
    800043c2:	69e2                	ld	s3,24(sp)
    800043c4:	6a42                	ld	s4,16(sp)
    800043c6:	6121                	addi	sp,sp,64
    800043c8:	8082                	ret

00000000800043ca <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800043ca:	711d                	addi	sp,sp,-96
    800043cc:	ec86                	sd	ra,88(sp)
    800043ce:	e8a2                	sd	s0,80(sp)
    800043d0:	e4a6                	sd	s1,72(sp)
    800043d2:	e0ca                	sd	s2,64(sp)
    800043d4:	fc4e                	sd	s3,56(sp)
    800043d6:	f852                	sd	s4,48(sp)
    800043d8:	f456                	sd	s5,40(sp)
    800043da:	f05a                	sd	s6,32(sp)
    800043dc:	ec5e                	sd	s7,24(sp)
    800043de:	e862                	sd	s8,16(sp)
    800043e0:	e466                	sd	s9,8(sp)
    800043e2:	1080                	addi	s0,sp,96
    800043e4:	84aa                	mv	s1,a0
    800043e6:	8aae                	mv	s5,a1
    800043e8:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800043ea:	00054703          	lbu	a4,0(a0)
    800043ee:	02f00793          	li	a5,47
    800043f2:	02f70363          	beq	a4,a5,80004418 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800043f6:	ffffd097          	auipc	ra,0xffffd
    800043fa:	6d6080e7          	jalr	1750(ra) # 80001acc <myproc>
    800043fe:	15053503          	ld	a0,336(a0)
    80004402:	00000097          	auipc	ra,0x0
    80004406:	9f6080e7          	jalr	-1546(ra) # 80003df8 <idup>
    8000440a:	89aa                	mv	s3,a0
  while(*path == '/')
    8000440c:	02f00913          	li	s2,47
  len = path - s;
    80004410:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004412:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004414:	4b85                	li	s7,1
    80004416:	a865                	j	800044ce <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004418:	4585                	li	a1,1
    8000441a:	4505                	li	a0,1
    8000441c:	fffff097          	auipc	ra,0xfffff
    80004420:	6e2080e7          	jalr	1762(ra) # 80003afe <iget>
    80004424:	89aa                	mv	s3,a0
    80004426:	b7dd                	j	8000440c <namex+0x42>
      iunlockput(ip);
    80004428:	854e                	mv	a0,s3
    8000442a:	00000097          	auipc	ra,0x0
    8000442e:	c6e080e7          	jalr	-914(ra) # 80004098 <iunlockput>
      return 0;
    80004432:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004434:	854e                	mv	a0,s3
    80004436:	60e6                	ld	ra,88(sp)
    80004438:	6446                	ld	s0,80(sp)
    8000443a:	64a6                	ld	s1,72(sp)
    8000443c:	6906                	ld	s2,64(sp)
    8000443e:	79e2                	ld	s3,56(sp)
    80004440:	7a42                	ld	s4,48(sp)
    80004442:	7aa2                	ld	s5,40(sp)
    80004444:	7b02                	ld	s6,32(sp)
    80004446:	6be2                	ld	s7,24(sp)
    80004448:	6c42                	ld	s8,16(sp)
    8000444a:	6ca2                	ld	s9,8(sp)
    8000444c:	6125                	addi	sp,sp,96
    8000444e:	8082                	ret
      iunlock(ip);
    80004450:	854e                	mv	a0,s3
    80004452:	00000097          	auipc	ra,0x0
    80004456:	aa6080e7          	jalr	-1370(ra) # 80003ef8 <iunlock>
      return ip;
    8000445a:	bfe9                	j	80004434 <namex+0x6a>
      iunlockput(ip);
    8000445c:	854e                	mv	a0,s3
    8000445e:	00000097          	auipc	ra,0x0
    80004462:	c3a080e7          	jalr	-966(ra) # 80004098 <iunlockput>
      return 0;
    80004466:	89e6                	mv	s3,s9
    80004468:	b7f1                	j	80004434 <namex+0x6a>
  len = path - s;
    8000446a:	40b48633          	sub	a2,s1,a1
    8000446e:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004472:	099c5463          	bge	s8,s9,800044fa <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004476:	4639                	li	a2,14
    80004478:	8552                	mv	a0,s4
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	91a080e7          	jalr	-1766(ra) # 80000d94 <memmove>
  while(*path == '/')
    80004482:	0004c783          	lbu	a5,0(s1)
    80004486:	01279763          	bne	a5,s2,80004494 <namex+0xca>
    path++;
    8000448a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000448c:	0004c783          	lbu	a5,0(s1)
    80004490:	ff278de3          	beq	a5,s2,8000448a <namex+0xc0>
    ilock(ip);
    80004494:	854e                	mv	a0,s3
    80004496:	00000097          	auipc	ra,0x0
    8000449a:	9a0080e7          	jalr	-1632(ra) # 80003e36 <ilock>
    if(ip->type != T_DIR){
    8000449e:	04499783          	lh	a5,68(s3)
    800044a2:	f97793e3          	bne	a5,s7,80004428 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800044a6:	000a8563          	beqz	s5,800044b0 <namex+0xe6>
    800044aa:	0004c783          	lbu	a5,0(s1)
    800044ae:	d3cd                	beqz	a5,80004450 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800044b0:	865a                	mv	a2,s6
    800044b2:	85d2                	mv	a1,s4
    800044b4:	854e                	mv	a0,s3
    800044b6:	00000097          	auipc	ra,0x0
    800044ba:	e64080e7          	jalr	-412(ra) # 8000431a <dirlookup>
    800044be:	8caa                	mv	s9,a0
    800044c0:	dd51                	beqz	a0,8000445c <namex+0x92>
    iunlockput(ip);
    800044c2:	854e                	mv	a0,s3
    800044c4:	00000097          	auipc	ra,0x0
    800044c8:	bd4080e7          	jalr	-1068(ra) # 80004098 <iunlockput>
    ip = next;
    800044cc:	89e6                	mv	s3,s9
  while(*path == '/')
    800044ce:	0004c783          	lbu	a5,0(s1)
    800044d2:	05279763          	bne	a5,s2,80004520 <namex+0x156>
    path++;
    800044d6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044d8:	0004c783          	lbu	a5,0(s1)
    800044dc:	ff278de3          	beq	a5,s2,800044d6 <namex+0x10c>
  if(*path == 0)
    800044e0:	c79d                	beqz	a5,8000450e <namex+0x144>
    path++;
    800044e2:	85a6                	mv	a1,s1
  len = path - s;
    800044e4:	8cda                	mv	s9,s6
    800044e6:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800044e8:	01278963          	beq	a5,s2,800044fa <namex+0x130>
    800044ec:	dfbd                	beqz	a5,8000446a <namex+0xa0>
    path++;
    800044ee:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800044f0:	0004c783          	lbu	a5,0(s1)
    800044f4:	ff279ce3          	bne	a5,s2,800044ec <namex+0x122>
    800044f8:	bf8d                	j	8000446a <namex+0xa0>
    memmove(name, s, len);
    800044fa:	2601                	sext.w	a2,a2
    800044fc:	8552                	mv	a0,s4
    800044fe:	ffffd097          	auipc	ra,0xffffd
    80004502:	896080e7          	jalr	-1898(ra) # 80000d94 <memmove>
    name[len] = 0;
    80004506:	9cd2                	add	s9,s9,s4
    80004508:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000450c:	bf9d                	j	80004482 <namex+0xb8>
  if(nameiparent){
    8000450e:	f20a83e3          	beqz	s5,80004434 <namex+0x6a>
    iput(ip);
    80004512:	854e                	mv	a0,s3
    80004514:	00000097          	auipc	ra,0x0
    80004518:	adc080e7          	jalr	-1316(ra) # 80003ff0 <iput>
    return 0;
    8000451c:	4981                	li	s3,0
    8000451e:	bf19                	j	80004434 <namex+0x6a>
  if(*path == 0)
    80004520:	d7fd                	beqz	a5,8000450e <namex+0x144>
  while(*path != '/' && *path != 0)
    80004522:	0004c783          	lbu	a5,0(s1)
    80004526:	85a6                	mv	a1,s1
    80004528:	b7d1                	j	800044ec <namex+0x122>

000000008000452a <dirlink>:
{
    8000452a:	7139                	addi	sp,sp,-64
    8000452c:	fc06                	sd	ra,56(sp)
    8000452e:	f822                	sd	s0,48(sp)
    80004530:	f426                	sd	s1,40(sp)
    80004532:	f04a                	sd	s2,32(sp)
    80004534:	ec4e                	sd	s3,24(sp)
    80004536:	e852                	sd	s4,16(sp)
    80004538:	0080                	addi	s0,sp,64
    8000453a:	892a                	mv	s2,a0
    8000453c:	8a2e                	mv	s4,a1
    8000453e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004540:	4601                	li	a2,0
    80004542:	00000097          	auipc	ra,0x0
    80004546:	dd8080e7          	jalr	-552(ra) # 8000431a <dirlookup>
    8000454a:	e93d                	bnez	a0,800045c0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000454c:	04c92483          	lw	s1,76(s2)
    80004550:	c49d                	beqz	s1,8000457e <dirlink+0x54>
    80004552:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004554:	4741                	li	a4,16
    80004556:	86a6                	mv	a3,s1
    80004558:	fc040613          	addi	a2,s0,-64
    8000455c:	4581                	li	a1,0
    8000455e:	854a                	mv	a0,s2
    80004560:	00000097          	auipc	ra,0x0
    80004564:	b8a080e7          	jalr	-1142(ra) # 800040ea <readi>
    80004568:	47c1                	li	a5,16
    8000456a:	06f51163          	bne	a0,a5,800045cc <dirlink+0xa2>
    if(de.inum == 0)
    8000456e:	fc045783          	lhu	a5,-64(s0)
    80004572:	c791                	beqz	a5,8000457e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004574:	24c1                	addiw	s1,s1,16
    80004576:	04c92783          	lw	a5,76(s2)
    8000457a:	fcf4ede3          	bltu	s1,a5,80004554 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000457e:	4639                	li	a2,14
    80004580:	85d2                	mv	a1,s4
    80004582:	fc240513          	addi	a0,s0,-62
    80004586:	ffffd097          	auipc	ra,0xffffd
    8000458a:	8be080e7          	jalr	-1858(ra) # 80000e44 <strncpy>
  de.inum = inum;
    8000458e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004592:	4741                	li	a4,16
    80004594:	86a6                	mv	a3,s1
    80004596:	fc040613          	addi	a2,s0,-64
    8000459a:	4581                	li	a1,0
    8000459c:	854a                	mv	a0,s2
    8000459e:	00000097          	auipc	ra,0x0
    800045a2:	c44080e7          	jalr	-956(ra) # 800041e2 <writei>
    800045a6:	1541                	addi	a0,a0,-16
    800045a8:	00a03533          	snez	a0,a0
    800045ac:	40a00533          	neg	a0,a0
}
    800045b0:	70e2                	ld	ra,56(sp)
    800045b2:	7442                	ld	s0,48(sp)
    800045b4:	74a2                	ld	s1,40(sp)
    800045b6:	7902                	ld	s2,32(sp)
    800045b8:	69e2                	ld	s3,24(sp)
    800045ba:	6a42                	ld	s4,16(sp)
    800045bc:	6121                	addi	sp,sp,64
    800045be:	8082                	ret
    iput(ip);
    800045c0:	00000097          	auipc	ra,0x0
    800045c4:	a30080e7          	jalr	-1488(ra) # 80003ff0 <iput>
    return -1;
    800045c8:	557d                	li	a0,-1
    800045ca:	b7dd                	j	800045b0 <dirlink+0x86>
      panic("dirlink read");
    800045cc:	00004517          	auipc	a0,0x4
    800045d0:	06450513          	addi	a0,a0,100 # 80008630 <syscalls+0x1e0>
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	f6a080e7          	jalr	-150(ra) # 8000053e <panic>

00000000800045dc <namei>:

struct inode*
namei(char *path)
{
    800045dc:	1101                	addi	sp,sp,-32
    800045de:	ec06                	sd	ra,24(sp)
    800045e0:	e822                	sd	s0,16(sp)
    800045e2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800045e4:	fe040613          	addi	a2,s0,-32
    800045e8:	4581                	li	a1,0
    800045ea:	00000097          	auipc	ra,0x0
    800045ee:	de0080e7          	jalr	-544(ra) # 800043ca <namex>
}
    800045f2:	60e2                	ld	ra,24(sp)
    800045f4:	6442                	ld	s0,16(sp)
    800045f6:	6105                	addi	sp,sp,32
    800045f8:	8082                	ret

00000000800045fa <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800045fa:	1141                	addi	sp,sp,-16
    800045fc:	e406                	sd	ra,8(sp)
    800045fe:	e022                	sd	s0,0(sp)
    80004600:	0800                	addi	s0,sp,16
    80004602:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004604:	4585                	li	a1,1
    80004606:	00000097          	auipc	ra,0x0
    8000460a:	dc4080e7          	jalr	-572(ra) # 800043ca <namex>
}
    8000460e:	60a2                	ld	ra,8(sp)
    80004610:	6402                	ld	s0,0(sp)
    80004612:	0141                	addi	sp,sp,16
    80004614:	8082                	ret

0000000080004616 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004616:	1101                	addi	sp,sp,-32
    80004618:	ec06                	sd	ra,24(sp)
    8000461a:	e822                	sd	s0,16(sp)
    8000461c:	e426                	sd	s1,8(sp)
    8000461e:	e04a                	sd	s2,0(sp)
    80004620:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004622:	0023d917          	auipc	s2,0x23d
    80004626:	11690913          	addi	s2,s2,278 # 80241738 <log>
    8000462a:	01892583          	lw	a1,24(s2)
    8000462e:	02892503          	lw	a0,40(s2)
    80004632:	fffff097          	auipc	ra,0xfffff
    80004636:	fea080e7          	jalr	-22(ra) # 8000361c <bread>
    8000463a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000463c:	02c92683          	lw	a3,44(s2)
    80004640:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004642:	02d05763          	blez	a3,80004670 <write_head+0x5a>
    80004646:	0023d797          	auipc	a5,0x23d
    8000464a:	12278793          	addi	a5,a5,290 # 80241768 <log+0x30>
    8000464e:	05c50713          	addi	a4,a0,92
    80004652:	36fd                	addiw	a3,a3,-1
    80004654:	1682                	slli	a3,a3,0x20
    80004656:	9281                	srli	a3,a3,0x20
    80004658:	068a                	slli	a3,a3,0x2
    8000465a:	0023d617          	auipc	a2,0x23d
    8000465e:	11260613          	addi	a2,a2,274 # 8024176c <log+0x34>
    80004662:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004664:	4390                	lw	a2,0(a5)
    80004666:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004668:	0791                	addi	a5,a5,4
    8000466a:	0711                	addi	a4,a4,4
    8000466c:	fed79ce3          	bne	a5,a3,80004664 <write_head+0x4e>
  }
  bwrite(buf);
    80004670:	8526                	mv	a0,s1
    80004672:	fffff097          	auipc	ra,0xfffff
    80004676:	09c080e7          	jalr	156(ra) # 8000370e <bwrite>
  brelse(buf);
    8000467a:	8526                	mv	a0,s1
    8000467c:	fffff097          	auipc	ra,0xfffff
    80004680:	0d0080e7          	jalr	208(ra) # 8000374c <brelse>
}
    80004684:	60e2                	ld	ra,24(sp)
    80004686:	6442                	ld	s0,16(sp)
    80004688:	64a2                	ld	s1,8(sp)
    8000468a:	6902                	ld	s2,0(sp)
    8000468c:	6105                	addi	sp,sp,32
    8000468e:	8082                	ret

0000000080004690 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004690:	0023d797          	auipc	a5,0x23d
    80004694:	0d47a783          	lw	a5,212(a5) # 80241764 <log+0x2c>
    80004698:	0af05d63          	blez	a5,80004752 <install_trans+0xc2>
{
    8000469c:	7139                	addi	sp,sp,-64
    8000469e:	fc06                	sd	ra,56(sp)
    800046a0:	f822                	sd	s0,48(sp)
    800046a2:	f426                	sd	s1,40(sp)
    800046a4:	f04a                	sd	s2,32(sp)
    800046a6:	ec4e                	sd	s3,24(sp)
    800046a8:	e852                	sd	s4,16(sp)
    800046aa:	e456                	sd	s5,8(sp)
    800046ac:	e05a                	sd	s6,0(sp)
    800046ae:	0080                	addi	s0,sp,64
    800046b0:	8b2a                	mv	s6,a0
    800046b2:	0023da97          	auipc	s5,0x23d
    800046b6:	0b6a8a93          	addi	s5,s5,182 # 80241768 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046ba:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046bc:	0023d997          	auipc	s3,0x23d
    800046c0:	07c98993          	addi	s3,s3,124 # 80241738 <log>
    800046c4:	a00d                	j	800046e6 <install_trans+0x56>
    brelse(lbuf);
    800046c6:	854a                	mv	a0,s2
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	084080e7          	jalr	132(ra) # 8000374c <brelse>
    brelse(dbuf);
    800046d0:	8526                	mv	a0,s1
    800046d2:	fffff097          	auipc	ra,0xfffff
    800046d6:	07a080e7          	jalr	122(ra) # 8000374c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046da:	2a05                	addiw	s4,s4,1
    800046dc:	0a91                	addi	s5,s5,4
    800046de:	02c9a783          	lw	a5,44(s3)
    800046e2:	04fa5e63          	bge	s4,a5,8000473e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046e6:	0189a583          	lw	a1,24(s3)
    800046ea:	014585bb          	addw	a1,a1,s4
    800046ee:	2585                	addiw	a1,a1,1
    800046f0:	0289a503          	lw	a0,40(s3)
    800046f4:	fffff097          	auipc	ra,0xfffff
    800046f8:	f28080e7          	jalr	-216(ra) # 8000361c <bread>
    800046fc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046fe:	000aa583          	lw	a1,0(s5)
    80004702:	0289a503          	lw	a0,40(s3)
    80004706:	fffff097          	auipc	ra,0xfffff
    8000470a:	f16080e7          	jalr	-234(ra) # 8000361c <bread>
    8000470e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004710:	40000613          	li	a2,1024
    80004714:	05890593          	addi	a1,s2,88
    80004718:	05850513          	addi	a0,a0,88
    8000471c:	ffffc097          	auipc	ra,0xffffc
    80004720:	678080e7          	jalr	1656(ra) # 80000d94 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004724:	8526                	mv	a0,s1
    80004726:	fffff097          	auipc	ra,0xfffff
    8000472a:	fe8080e7          	jalr	-24(ra) # 8000370e <bwrite>
    if(recovering == 0)
    8000472e:	f80b1ce3          	bnez	s6,800046c6 <install_trans+0x36>
      bunpin(dbuf);
    80004732:	8526                	mv	a0,s1
    80004734:	fffff097          	auipc	ra,0xfffff
    80004738:	0f2080e7          	jalr	242(ra) # 80003826 <bunpin>
    8000473c:	b769                	j	800046c6 <install_trans+0x36>
}
    8000473e:	70e2                	ld	ra,56(sp)
    80004740:	7442                	ld	s0,48(sp)
    80004742:	74a2                	ld	s1,40(sp)
    80004744:	7902                	ld	s2,32(sp)
    80004746:	69e2                	ld	s3,24(sp)
    80004748:	6a42                	ld	s4,16(sp)
    8000474a:	6aa2                	ld	s5,8(sp)
    8000474c:	6b02                	ld	s6,0(sp)
    8000474e:	6121                	addi	sp,sp,64
    80004750:	8082                	ret
    80004752:	8082                	ret

0000000080004754 <initlog>:
{
    80004754:	7179                	addi	sp,sp,-48
    80004756:	f406                	sd	ra,40(sp)
    80004758:	f022                	sd	s0,32(sp)
    8000475a:	ec26                	sd	s1,24(sp)
    8000475c:	e84a                	sd	s2,16(sp)
    8000475e:	e44e                	sd	s3,8(sp)
    80004760:	1800                	addi	s0,sp,48
    80004762:	892a                	mv	s2,a0
    80004764:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004766:	0023d497          	auipc	s1,0x23d
    8000476a:	fd248493          	addi	s1,s1,-46 # 80241738 <log>
    8000476e:	00004597          	auipc	a1,0x4
    80004772:	ed258593          	addi	a1,a1,-302 # 80008640 <syscalls+0x1f0>
    80004776:	8526                	mv	a0,s1
    80004778:	ffffc097          	auipc	ra,0xffffc
    8000477c:	434080e7          	jalr	1076(ra) # 80000bac <initlock>
  log.start = sb->logstart;
    80004780:	0149a583          	lw	a1,20(s3)
    80004784:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004786:	0109a783          	lw	a5,16(s3)
    8000478a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000478c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004790:	854a                	mv	a0,s2
    80004792:	fffff097          	auipc	ra,0xfffff
    80004796:	e8a080e7          	jalr	-374(ra) # 8000361c <bread>
  log.lh.n = lh->n;
    8000479a:	4d34                	lw	a3,88(a0)
    8000479c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000479e:	02d05563          	blez	a3,800047c8 <initlog+0x74>
    800047a2:	05c50793          	addi	a5,a0,92
    800047a6:	0023d717          	auipc	a4,0x23d
    800047aa:	fc270713          	addi	a4,a4,-62 # 80241768 <log+0x30>
    800047ae:	36fd                	addiw	a3,a3,-1
    800047b0:	1682                	slli	a3,a3,0x20
    800047b2:	9281                	srli	a3,a3,0x20
    800047b4:	068a                	slli	a3,a3,0x2
    800047b6:	06050613          	addi	a2,a0,96
    800047ba:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800047bc:	4390                	lw	a2,0(a5)
    800047be:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800047c0:	0791                	addi	a5,a5,4
    800047c2:	0711                	addi	a4,a4,4
    800047c4:	fed79ce3          	bne	a5,a3,800047bc <initlog+0x68>
  brelse(buf);
    800047c8:	fffff097          	auipc	ra,0xfffff
    800047cc:	f84080e7          	jalr	-124(ra) # 8000374c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800047d0:	4505                	li	a0,1
    800047d2:	00000097          	auipc	ra,0x0
    800047d6:	ebe080e7          	jalr	-322(ra) # 80004690 <install_trans>
  log.lh.n = 0;
    800047da:	0023d797          	auipc	a5,0x23d
    800047de:	f807a523          	sw	zero,-118(a5) # 80241764 <log+0x2c>
  write_head(); // clear the log
    800047e2:	00000097          	auipc	ra,0x0
    800047e6:	e34080e7          	jalr	-460(ra) # 80004616 <write_head>
}
    800047ea:	70a2                	ld	ra,40(sp)
    800047ec:	7402                	ld	s0,32(sp)
    800047ee:	64e2                	ld	s1,24(sp)
    800047f0:	6942                	ld	s2,16(sp)
    800047f2:	69a2                	ld	s3,8(sp)
    800047f4:	6145                	addi	sp,sp,48
    800047f6:	8082                	ret

00000000800047f8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800047f8:	1101                	addi	sp,sp,-32
    800047fa:	ec06                	sd	ra,24(sp)
    800047fc:	e822                	sd	s0,16(sp)
    800047fe:	e426                	sd	s1,8(sp)
    80004800:	e04a                	sd	s2,0(sp)
    80004802:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004804:	0023d517          	auipc	a0,0x23d
    80004808:	f3450513          	addi	a0,a0,-204 # 80241738 <log>
    8000480c:	ffffc097          	auipc	ra,0xffffc
    80004810:	430080e7          	jalr	1072(ra) # 80000c3c <acquire>
  while(1){
    if(log.committing){
    80004814:	0023d497          	auipc	s1,0x23d
    80004818:	f2448493          	addi	s1,s1,-220 # 80241738 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000481c:	4979                	li	s2,30
    8000481e:	a039                	j	8000482c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004820:	85a6                	mv	a1,s1
    80004822:	8526                	mv	a0,s1
    80004824:	ffffe097          	auipc	ra,0xffffe
    80004828:	cce080e7          	jalr	-818(ra) # 800024f2 <sleep>
    if(log.committing){
    8000482c:	50dc                	lw	a5,36(s1)
    8000482e:	fbed                	bnez	a5,80004820 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004830:	509c                	lw	a5,32(s1)
    80004832:	0017871b          	addiw	a4,a5,1
    80004836:	0007069b          	sext.w	a3,a4
    8000483a:	0027179b          	slliw	a5,a4,0x2
    8000483e:	9fb9                	addw	a5,a5,a4
    80004840:	0017979b          	slliw	a5,a5,0x1
    80004844:	54d8                	lw	a4,44(s1)
    80004846:	9fb9                	addw	a5,a5,a4
    80004848:	00f95963          	bge	s2,a5,8000485a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000484c:	85a6                	mv	a1,s1
    8000484e:	8526                	mv	a0,s1
    80004850:	ffffe097          	auipc	ra,0xffffe
    80004854:	ca2080e7          	jalr	-862(ra) # 800024f2 <sleep>
    80004858:	bfd1                	j	8000482c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000485a:	0023d517          	auipc	a0,0x23d
    8000485e:	ede50513          	addi	a0,a0,-290 # 80241738 <log>
    80004862:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004864:	ffffc097          	auipc	ra,0xffffc
    80004868:	48c080e7          	jalr	1164(ra) # 80000cf0 <release>
      break;
    }
  }
}
    8000486c:	60e2                	ld	ra,24(sp)
    8000486e:	6442                	ld	s0,16(sp)
    80004870:	64a2                	ld	s1,8(sp)
    80004872:	6902                	ld	s2,0(sp)
    80004874:	6105                	addi	sp,sp,32
    80004876:	8082                	ret

0000000080004878 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004878:	7139                	addi	sp,sp,-64
    8000487a:	fc06                	sd	ra,56(sp)
    8000487c:	f822                	sd	s0,48(sp)
    8000487e:	f426                	sd	s1,40(sp)
    80004880:	f04a                	sd	s2,32(sp)
    80004882:	ec4e                	sd	s3,24(sp)
    80004884:	e852                	sd	s4,16(sp)
    80004886:	e456                	sd	s5,8(sp)
    80004888:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000488a:	0023d497          	auipc	s1,0x23d
    8000488e:	eae48493          	addi	s1,s1,-338 # 80241738 <log>
    80004892:	8526                	mv	a0,s1
    80004894:	ffffc097          	auipc	ra,0xffffc
    80004898:	3a8080e7          	jalr	936(ra) # 80000c3c <acquire>
  log.outstanding -= 1;
    8000489c:	509c                	lw	a5,32(s1)
    8000489e:	37fd                	addiw	a5,a5,-1
    800048a0:	0007891b          	sext.w	s2,a5
    800048a4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800048a6:	50dc                	lw	a5,36(s1)
    800048a8:	e7b9                	bnez	a5,800048f6 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800048aa:	04091e63          	bnez	s2,80004906 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800048ae:	0023d497          	auipc	s1,0x23d
    800048b2:	e8a48493          	addi	s1,s1,-374 # 80241738 <log>
    800048b6:	4785                	li	a5,1
    800048b8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800048ba:	8526                	mv	a0,s1
    800048bc:	ffffc097          	auipc	ra,0xffffc
    800048c0:	434080e7          	jalr	1076(ra) # 80000cf0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800048c4:	54dc                	lw	a5,44(s1)
    800048c6:	06f04763          	bgtz	a5,80004934 <end_op+0xbc>
    acquire(&log.lock);
    800048ca:	0023d497          	auipc	s1,0x23d
    800048ce:	e6e48493          	addi	s1,s1,-402 # 80241738 <log>
    800048d2:	8526                	mv	a0,s1
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	368080e7          	jalr	872(ra) # 80000c3c <acquire>
    log.committing = 0;
    800048dc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800048e0:	8526                	mv	a0,s1
    800048e2:	ffffe097          	auipc	ra,0xffffe
    800048e6:	c74080e7          	jalr	-908(ra) # 80002556 <wakeup>
    release(&log.lock);
    800048ea:	8526                	mv	a0,s1
    800048ec:	ffffc097          	auipc	ra,0xffffc
    800048f0:	404080e7          	jalr	1028(ra) # 80000cf0 <release>
}
    800048f4:	a03d                	j	80004922 <end_op+0xaa>
    panic("log.committing");
    800048f6:	00004517          	auipc	a0,0x4
    800048fa:	d5250513          	addi	a0,a0,-686 # 80008648 <syscalls+0x1f8>
    800048fe:	ffffc097          	auipc	ra,0xffffc
    80004902:	c40080e7          	jalr	-960(ra) # 8000053e <panic>
    wakeup(&log);
    80004906:	0023d497          	auipc	s1,0x23d
    8000490a:	e3248493          	addi	s1,s1,-462 # 80241738 <log>
    8000490e:	8526                	mv	a0,s1
    80004910:	ffffe097          	auipc	ra,0xffffe
    80004914:	c46080e7          	jalr	-954(ra) # 80002556 <wakeup>
  release(&log.lock);
    80004918:	8526                	mv	a0,s1
    8000491a:	ffffc097          	auipc	ra,0xffffc
    8000491e:	3d6080e7          	jalr	982(ra) # 80000cf0 <release>
}
    80004922:	70e2                	ld	ra,56(sp)
    80004924:	7442                	ld	s0,48(sp)
    80004926:	74a2                	ld	s1,40(sp)
    80004928:	7902                	ld	s2,32(sp)
    8000492a:	69e2                	ld	s3,24(sp)
    8000492c:	6a42                	ld	s4,16(sp)
    8000492e:	6aa2                	ld	s5,8(sp)
    80004930:	6121                	addi	sp,sp,64
    80004932:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004934:	0023da97          	auipc	s5,0x23d
    80004938:	e34a8a93          	addi	s5,s5,-460 # 80241768 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000493c:	0023da17          	auipc	s4,0x23d
    80004940:	dfca0a13          	addi	s4,s4,-516 # 80241738 <log>
    80004944:	018a2583          	lw	a1,24(s4)
    80004948:	012585bb          	addw	a1,a1,s2
    8000494c:	2585                	addiw	a1,a1,1
    8000494e:	028a2503          	lw	a0,40(s4)
    80004952:	fffff097          	auipc	ra,0xfffff
    80004956:	cca080e7          	jalr	-822(ra) # 8000361c <bread>
    8000495a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000495c:	000aa583          	lw	a1,0(s5)
    80004960:	028a2503          	lw	a0,40(s4)
    80004964:	fffff097          	auipc	ra,0xfffff
    80004968:	cb8080e7          	jalr	-840(ra) # 8000361c <bread>
    8000496c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000496e:	40000613          	li	a2,1024
    80004972:	05850593          	addi	a1,a0,88
    80004976:	05848513          	addi	a0,s1,88
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	41a080e7          	jalr	1050(ra) # 80000d94 <memmove>
    bwrite(to);  // write the log
    80004982:	8526                	mv	a0,s1
    80004984:	fffff097          	auipc	ra,0xfffff
    80004988:	d8a080e7          	jalr	-630(ra) # 8000370e <bwrite>
    brelse(from);
    8000498c:	854e                	mv	a0,s3
    8000498e:	fffff097          	auipc	ra,0xfffff
    80004992:	dbe080e7          	jalr	-578(ra) # 8000374c <brelse>
    brelse(to);
    80004996:	8526                	mv	a0,s1
    80004998:	fffff097          	auipc	ra,0xfffff
    8000499c:	db4080e7          	jalr	-588(ra) # 8000374c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049a0:	2905                	addiw	s2,s2,1
    800049a2:	0a91                	addi	s5,s5,4
    800049a4:	02ca2783          	lw	a5,44(s4)
    800049a8:	f8f94ee3          	blt	s2,a5,80004944 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800049ac:	00000097          	auipc	ra,0x0
    800049b0:	c6a080e7          	jalr	-918(ra) # 80004616 <write_head>
    install_trans(0); // Now install writes to home locations
    800049b4:	4501                	li	a0,0
    800049b6:	00000097          	auipc	ra,0x0
    800049ba:	cda080e7          	jalr	-806(ra) # 80004690 <install_trans>
    log.lh.n = 0;
    800049be:	0023d797          	auipc	a5,0x23d
    800049c2:	da07a323          	sw	zero,-602(a5) # 80241764 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800049c6:	00000097          	auipc	ra,0x0
    800049ca:	c50080e7          	jalr	-944(ra) # 80004616 <write_head>
    800049ce:	bdf5                	j	800048ca <end_op+0x52>

00000000800049d0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800049d0:	1101                	addi	sp,sp,-32
    800049d2:	ec06                	sd	ra,24(sp)
    800049d4:	e822                	sd	s0,16(sp)
    800049d6:	e426                	sd	s1,8(sp)
    800049d8:	e04a                	sd	s2,0(sp)
    800049da:	1000                	addi	s0,sp,32
    800049dc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800049de:	0023d917          	auipc	s2,0x23d
    800049e2:	d5a90913          	addi	s2,s2,-678 # 80241738 <log>
    800049e6:	854a                	mv	a0,s2
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	254080e7          	jalr	596(ra) # 80000c3c <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800049f0:	02c92603          	lw	a2,44(s2)
    800049f4:	47f5                	li	a5,29
    800049f6:	06c7c563          	blt	a5,a2,80004a60 <log_write+0x90>
    800049fa:	0023d797          	auipc	a5,0x23d
    800049fe:	d5a7a783          	lw	a5,-678(a5) # 80241754 <log+0x1c>
    80004a02:	37fd                	addiw	a5,a5,-1
    80004a04:	04f65e63          	bge	a2,a5,80004a60 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004a08:	0023d797          	auipc	a5,0x23d
    80004a0c:	d507a783          	lw	a5,-688(a5) # 80241758 <log+0x20>
    80004a10:	06f05063          	blez	a5,80004a70 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004a14:	4781                	li	a5,0
    80004a16:	06c05563          	blez	a2,80004a80 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a1a:	44cc                	lw	a1,12(s1)
    80004a1c:	0023d717          	auipc	a4,0x23d
    80004a20:	d4c70713          	addi	a4,a4,-692 # 80241768 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a24:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a26:	4314                	lw	a3,0(a4)
    80004a28:	04b68c63          	beq	a3,a1,80004a80 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004a2c:	2785                	addiw	a5,a5,1
    80004a2e:	0711                	addi	a4,a4,4
    80004a30:	fef61be3          	bne	a2,a5,80004a26 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a34:	0621                	addi	a2,a2,8
    80004a36:	060a                	slli	a2,a2,0x2
    80004a38:	0023d797          	auipc	a5,0x23d
    80004a3c:	d0078793          	addi	a5,a5,-768 # 80241738 <log>
    80004a40:	963e                	add	a2,a2,a5
    80004a42:	44dc                	lw	a5,12(s1)
    80004a44:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a46:	8526                	mv	a0,s1
    80004a48:	fffff097          	auipc	ra,0xfffff
    80004a4c:	da2080e7          	jalr	-606(ra) # 800037ea <bpin>
    log.lh.n++;
    80004a50:	0023d717          	auipc	a4,0x23d
    80004a54:	ce870713          	addi	a4,a4,-792 # 80241738 <log>
    80004a58:	575c                	lw	a5,44(a4)
    80004a5a:	2785                	addiw	a5,a5,1
    80004a5c:	d75c                	sw	a5,44(a4)
    80004a5e:	a835                	j	80004a9a <log_write+0xca>
    panic("too big a transaction");
    80004a60:	00004517          	auipc	a0,0x4
    80004a64:	bf850513          	addi	a0,a0,-1032 # 80008658 <syscalls+0x208>
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	ad6080e7          	jalr	-1322(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004a70:	00004517          	auipc	a0,0x4
    80004a74:	c0050513          	addi	a0,a0,-1024 # 80008670 <syscalls+0x220>
    80004a78:	ffffc097          	auipc	ra,0xffffc
    80004a7c:	ac6080e7          	jalr	-1338(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004a80:	00878713          	addi	a4,a5,8
    80004a84:	00271693          	slli	a3,a4,0x2
    80004a88:	0023d717          	auipc	a4,0x23d
    80004a8c:	cb070713          	addi	a4,a4,-848 # 80241738 <log>
    80004a90:	9736                	add	a4,a4,a3
    80004a92:	44d4                	lw	a3,12(s1)
    80004a94:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a96:	faf608e3          	beq	a2,a5,80004a46 <log_write+0x76>
  }
  release(&log.lock);
    80004a9a:	0023d517          	auipc	a0,0x23d
    80004a9e:	c9e50513          	addi	a0,a0,-866 # 80241738 <log>
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	24e080e7          	jalr	590(ra) # 80000cf0 <release>
}
    80004aaa:	60e2                	ld	ra,24(sp)
    80004aac:	6442                	ld	s0,16(sp)
    80004aae:	64a2                	ld	s1,8(sp)
    80004ab0:	6902                	ld	s2,0(sp)
    80004ab2:	6105                	addi	sp,sp,32
    80004ab4:	8082                	ret

0000000080004ab6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004ab6:	1101                	addi	sp,sp,-32
    80004ab8:	ec06                	sd	ra,24(sp)
    80004aba:	e822                	sd	s0,16(sp)
    80004abc:	e426                	sd	s1,8(sp)
    80004abe:	e04a                	sd	s2,0(sp)
    80004ac0:	1000                	addi	s0,sp,32
    80004ac2:	84aa                	mv	s1,a0
    80004ac4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004ac6:	00004597          	auipc	a1,0x4
    80004aca:	bca58593          	addi	a1,a1,-1078 # 80008690 <syscalls+0x240>
    80004ace:	0521                	addi	a0,a0,8
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	0dc080e7          	jalr	220(ra) # 80000bac <initlock>
  lk->name = name;
    80004ad8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004adc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ae0:	0204a423          	sw	zero,40(s1)
}
    80004ae4:	60e2                	ld	ra,24(sp)
    80004ae6:	6442                	ld	s0,16(sp)
    80004ae8:	64a2                	ld	s1,8(sp)
    80004aea:	6902                	ld	s2,0(sp)
    80004aec:	6105                	addi	sp,sp,32
    80004aee:	8082                	ret

0000000080004af0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004af0:	1101                	addi	sp,sp,-32
    80004af2:	ec06                	sd	ra,24(sp)
    80004af4:	e822                	sd	s0,16(sp)
    80004af6:	e426                	sd	s1,8(sp)
    80004af8:	e04a                	sd	s2,0(sp)
    80004afa:	1000                	addi	s0,sp,32
    80004afc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004afe:	00850913          	addi	s2,a0,8
    80004b02:	854a                	mv	a0,s2
    80004b04:	ffffc097          	auipc	ra,0xffffc
    80004b08:	138080e7          	jalr	312(ra) # 80000c3c <acquire>
  while (lk->locked) {
    80004b0c:	409c                	lw	a5,0(s1)
    80004b0e:	cb89                	beqz	a5,80004b20 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004b10:	85ca                	mv	a1,s2
    80004b12:	8526                	mv	a0,s1
    80004b14:	ffffe097          	auipc	ra,0xffffe
    80004b18:	9de080e7          	jalr	-1570(ra) # 800024f2 <sleep>
  while (lk->locked) {
    80004b1c:	409c                	lw	a5,0(s1)
    80004b1e:	fbed                	bnez	a5,80004b10 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b20:	4785                	li	a5,1
    80004b22:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b24:	ffffd097          	auipc	ra,0xffffd
    80004b28:	fa8080e7          	jalr	-88(ra) # 80001acc <myproc>
    80004b2c:	591c                	lw	a5,48(a0)
    80004b2e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b30:	854a                	mv	a0,s2
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	1be080e7          	jalr	446(ra) # 80000cf0 <release>
}
    80004b3a:	60e2                	ld	ra,24(sp)
    80004b3c:	6442                	ld	s0,16(sp)
    80004b3e:	64a2                	ld	s1,8(sp)
    80004b40:	6902                	ld	s2,0(sp)
    80004b42:	6105                	addi	sp,sp,32
    80004b44:	8082                	ret

0000000080004b46 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b46:	1101                	addi	sp,sp,-32
    80004b48:	ec06                	sd	ra,24(sp)
    80004b4a:	e822                	sd	s0,16(sp)
    80004b4c:	e426                	sd	s1,8(sp)
    80004b4e:	e04a                	sd	s2,0(sp)
    80004b50:	1000                	addi	s0,sp,32
    80004b52:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b54:	00850913          	addi	s2,a0,8
    80004b58:	854a                	mv	a0,s2
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	0e2080e7          	jalr	226(ra) # 80000c3c <acquire>
  lk->locked = 0;
    80004b62:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b66:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b6a:	8526                	mv	a0,s1
    80004b6c:	ffffe097          	auipc	ra,0xffffe
    80004b70:	9ea080e7          	jalr	-1558(ra) # 80002556 <wakeup>
  release(&lk->lk);
    80004b74:	854a                	mv	a0,s2
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	17a080e7          	jalr	378(ra) # 80000cf0 <release>
}
    80004b7e:	60e2                	ld	ra,24(sp)
    80004b80:	6442                	ld	s0,16(sp)
    80004b82:	64a2                	ld	s1,8(sp)
    80004b84:	6902                	ld	s2,0(sp)
    80004b86:	6105                	addi	sp,sp,32
    80004b88:	8082                	ret

0000000080004b8a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b8a:	7179                	addi	sp,sp,-48
    80004b8c:	f406                	sd	ra,40(sp)
    80004b8e:	f022                	sd	s0,32(sp)
    80004b90:	ec26                	sd	s1,24(sp)
    80004b92:	e84a                	sd	s2,16(sp)
    80004b94:	e44e                	sd	s3,8(sp)
    80004b96:	1800                	addi	s0,sp,48
    80004b98:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b9a:	00850913          	addi	s2,a0,8
    80004b9e:	854a                	mv	a0,s2
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	09c080e7          	jalr	156(ra) # 80000c3c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ba8:	409c                	lw	a5,0(s1)
    80004baa:	ef99                	bnez	a5,80004bc8 <holdingsleep+0x3e>
    80004bac:	4481                	li	s1,0
  release(&lk->lk);
    80004bae:	854a                	mv	a0,s2
    80004bb0:	ffffc097          	auipc	ra,0xffffc
    80004bb4:	140080e7          	jalr	320(ra) # 80000cf0 <release>
  return r;
}
    80004bb8:	8526                	mv	a0,s1
    80004bba:	70a2                	ld	ra,40(sp)
    80004bbc:	7402                	ld	s0,32(sp)
    80004bbe:	64e2                	ld	s1,24(sp)
    80004bc0:	6942                	ld	s2,16(sp)
    80004bc2:	69a2                	ld	s3,8(sp)
    80004bc4:	6145                	addi	sp,sp,48
    80004bc6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bc8:	0284a983          	lw	s3,40(s1)
    80004bcc:	ffffd097          	auipc	ra,0xffffd
    80004bd0:	f00080e7          	jalr	-256(ra) # 80001acc <myproc>
    80004bd4:	5904                	lw	s1,48(a0)
    80004bd6:	413484b3          	sub	s1,s1,s3
    80004bda:	0014b493          	seqz	s1,s1
    80004bde:	bfc1                	j	80004bae <holdingsleep+0x24>

0000000080004be0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004be0:	1141                	addi	sp,sp,-16
    80004be2:	e406                	sd	ra,8(sp)
    80004be4:	e022                	sd	s0,0(sp)
    80004be6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004be8:	00004597          	auipc	a1,0x4
    80004bec:	ab858593          	addi	a1,a1,-1352 # 800086a0 <syscalls+0x250>
    80004bf0:	0023d517          	auipc	a0,0x23d
    80004bf4:	c9050513          	addi	a0,a0,-880 # 80241880 <ftable>
    80004bf8:	ffffc097          	auipc	ra,0xffffc
    80004bfc:	fb4080e7          	jalr	-76(ra) # 80000bac <initlock>
}
    80004c00:	60a2                	ld	ra,8(sp)
    80004c02:	6402                	ld	s0,0(sp)
    80004c04:	0141                	addi	sp,sp,16
    80004c06:	8082                	ret

0000000080004c08 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004c08:	1101                	addi	sp,sp,-32
    80004c0a:	ec06                	sd	ra,24(sp)
    80004c0c:	e822                	sd	s0,16(sp)
    80004c0e:	e426                	sd	s1,8(sp)
    80004c10:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004c12:	0023d517          	auipc	a0,0x23d
    80004c16:	c6e50513          	addi	a0,a0,-914 # 80241880 <ftable>
    80004c1a:	ffffc097          	auipc	ra,0xffffc
    80004c1e:	022080e7          	jalr	34(ra) # 80000c3c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c22:	0023d497          	auipc	s1,0x23d
    80004c26:	c7648493          	addi	s1,s1,-906 # 80241898 <ftable+0x18>
    80004c2a:	0023e717          	auipc	a4,0x23e
    80004c2e:	c0e70713          	addi	a4,a4,-1010 # 80242838 <disk>
    if(f->ref == 0){
    80004c32:	40dc                	lw	a5,4(s1)
    80004c34:	cf99                	beqz	a5,80004c52 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c36:	02848493          	addi	s1,s1,40
    80004c3a:	fee49ce3          	bne	s1,a4,80004c32 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c3e:	0023d517          	auipc	a0,0x23d
    80004c42:	c4250513          	addi	a0,a0,-958 # 80241880 <ftable>
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	0aa080e7          	jalr	170(ra) # 80000cf0 <release>
  return 0;
    80004c4e:	4481                	li	s1,0
    80004c50:	a819                	j	80004c66 <filealloc+0x5e>
      f->ref = 1;
    80004c52:	4785                	li	a5,1
    80004c54:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c56:	0023d517          	auipc	a0,0x23d
    80004c5a:	c2a50513          	addi	a0,a0,-982 # 80241880 <ftable>
    80004c5e:	ffffc097          	auipc	ra,0xffffc
    80004c62:	092080e7          	jalr	146(ra) # 80000cf0 <release>
}
    80004c66:	8526                	mv	a0,s1
    80004c68:	60e2                	ld	ra,24(sp)
    80004c6a:	6442                	ld	s0,16(sp)
    80004c6c:	64a2                	ld	s1,8(sp)
    80004c6e:	6105                	addi	sp,sp,32
    80004c70:	8082                	ret

0000000080004c72 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c72:	1101                	addi	sp,sp,-32
    80004c74:	ec06                	sd	ra,24(sp)
    80004c76:	e822                	sd	s0,16(sp)
    80004c78:	e426                	sd	s1,8(sp)
    80004c7a:	1000                	addi	s0,sp,32
    80004c7c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c7e:	0023d517          	auipc	a0,0x23d
    80004c82:	c0250513          	addi	a0,a0,-1022 # 80241880 <ftable>
    80004c86:	ffffc097          	auipc	ra,0xffffc
    80004c8a:	fb6080e7          	jalr	-74(ra) # 80000c3c <acquire>
  if(f->ref < 1)
    80004c8e:	40dc                	lw	a5,4(s1)
    80004c90:	02f05263          	blez	a5,80004cb4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c94:	2785                	addiw	a5,a5,1
    80004c96:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c98:	0023d517          	auipc	a0,0x23d
    80004c9c:	be850513          	addi	a0,a0,-1048 # 80241880 <ftable>
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	050080e7          	jalr	80(ra) # 80000cf0 <release>
  return f;
}
    80004ca8:	8526                	mv	a0,s1
    80004caa:	60e2                	ld	ra,24(sp)
    80004cac:	6442                	ld	s0,16(sp)
    80004cae:	64a2                	ld	s1,8(sp)
    80004cb0:	6105                	addi	sp,sp,32
    80004cb2:	8082                	ret
    panic("filedup");
    80004cb4:	00004517          	auipc	a0,0x4
    80004cb8:	9f450513          	addi	a0,a0,-1548 # 800086a8 <syscalls+0x258>
    80004cbc:	ffffc097          	auipc	ra,0xffffc
    80004cc0:	882080e7          	jalr	-1918(ra) # 8000053e <panic>

0000000080004cc4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004cc4:	7139                	addi	sp,sp,-64
    80004cc6:	fc06                	sd	ra,56(sp)
    80004cc8:	f822                	sd	s0,48(sp)
    80004cca:	f426                	sd	s1,40(sp)
    80004ccc:	f04a                	sd	s2,32(sp)
    80004cce:	ec4e                	sd	s3,24(sp)
    80004cd0:	e852                	sd	s4,16(sp)
    80004cd2:	e456                	sd	s5,8(sp)
    80004cd4:	0080                	addi	s0,sp,64
    80004cd6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004cd8:	0023d517          	auipc	a0,0x23d
    80004cdc:	ba850513          	addi	a0,a0,-1112 # 80241880 <ftable>
    80004ce0:	ffffc097          	auipc	ra,0xffffc
    80004ce4:	f5c080e7          	jalr	-164(ra) # 80000c3c <acquire>
  if(f->ref < 1)
    80004ce8:	40dc                	lw	a5,4(s1)
    80004cea:	06f05163          	blez	a5,80004d4c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004cee:	37fd                	addiw	a5,a5,-1
    80004cf0:	0007871b          	sext.w	a4,a5
    80004cf4:	c0dc                	sw	a5,4(s1)
    80004cf6:	06e04363          	bgtz	a4,80004d5c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004cfa:	0004a903          	lw	s2,0(s1)
    80004cfe:	0094ca83          	lbu	s5,9(s1)
    80004d02:	0104ba03          	ld	s4,16(s1)
    80004d06:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004d0a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004d0e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004d12:	0023d517          	auipc	a0,0x23d
    80004d16:	b6e50513          	addi	a0,a0,-1170 # 80241880 <ftable>
    80004d1a:	ffffc097          	auipc	ra,0xffffc
    80004d1e:	fd6080e7          	jalr	-42(ra) # 80000cf0 <release>

  if(ff.type == FD_PIPE){
    80004d22:	4785                	li	a5,1
    80004d24:	04f90d63          	beq	s2,a5,80004d7e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d28:	3979                	addiw	s2,s2,-2
    80004d2a:	4785                	li	a5,1
    80004d2c:	0527e063          	bltu	a5,s2,80004d6c <fileclose+0xa8>
    begin_op();
    80004d30:	00000097          	auipc	ra,0x0
    80004d34:	ac8080e7          	jalr	-1336(ra) # 800047f8 <begin_op>
    iput(ff.ip);
    80004d38:	854e                	mv	a0,s3
    80004d3a:	fffff097          	auipc	ra,0xfffff
    80004d3e:	2b6080e7          	jalr	694(ra) # 80003ff0 <iput>
    end_op();
    80004d42:	00000097          	auipc	ra,0x0
    80004d46:	b36080e7          	jalr	-1226(ra) # 80004878 <end_op>
    80004d4a:	a00d                	j	80004d6c <fileclose+0xa8>
    panic("fileclose");
    80004d4c:	00004517          	auipc	a0,0x4
    80004d50:	96450513          	addi	a0,a0,-1692 # 800086b0 <syscalls+0x260>
    80004d54:	ffffb097          	auipc	ra,0xffffb
    80004d58:	7ea080e7          	jalr	2026(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004d5c:	0023d517          	auipc	a0,0x23d
    80004d60:	b2450513          	addi	a0,a0,-1244 # 80241880 <ftable>
    80004d64:	ffffc097          	auipc	ra,0xffffc
    80004d68:	f8c080e7          	jalr	-116(ra) # 80000cf0 <release>
  }
}
    80004d6c:	70e2                	ld	ra,56(sp)
    80004d6e:	7442                	ld	s0,48(sp)
    80004d70:	74a2                	ld	s1,40(sp)
    80004d72:	7902                	ld	s2,32(sp)
    80004d74:	69e2                	ld	s3,24(sp)
    80004d76:	6a42                	ld	s4,16(sp)
    80004d78:	6aa2                	ld	s5,8(sp)
    80004d7a:	6121                	addi	sp,sp,64
    80004d7c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d7e:	85d6                	mv	a1,s5
    80004d80:	8552                	mv	a0,s4
    80004d82:	00000097          	auipc	ra,0x0
    80004d86:	34c080e7          	jalr	844(ra) # 800050ce <pipeclose>
    80004d8a:	b7cd                	j	80004d6c <fileclose+0xa8>

0000000080004d8c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d8c:	715d                	addi	sp,sp,-80
    80004d8e:	e486                	sd	ra,72(sp)
    80004d90:	e0a2                	sd	s0,64(sp)
    80004d92:	fc26                	sd	s1,56(sp)
    80004d94:	f84a                	sd	s2,48(sp)
    80004d96:	f44e                	sd	s3,40(sp)
    80004d98:	0880                	addi	s0,sp,80
    80004d9a:	84aa                	mv	s1,a0
    80004d9c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d9e:	ffffd097          	auipc	ra,0xffffd
    80004da2:	d2e080e7          	jalr	-722(ra) # 80001acc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004da6:	409c                	lw	a5,0(s1)
    80004da8:	37f9                	addiw	a5,a5,-2
    80004daa:	4705                	li	a4,1
    80004dac:	04f76763          	bltu	a4,a5,80004dfa <filestat+0x6e>
    80004db0:	892a                	mv	s2,a0
    ilock(f->ip);
    80004db2:	6c88                	ld	a0,24(s1)
    80004db4:	fffff097          	auipc	ra,0xfffff
    80004db8:	082080e7          	jalr	130(ra) # 80003e36 <ilock>
    stati(f->ip, &st);
    80004dbc:	fb840593          	addi	a1,s0,-72
    80004dc0:	6c88                	ld	a0,24(s1)
    80004dc2:	fffff097          	auipc	ra,0xfffff
    80004dc6:	2fe080e7          	jalr	766(ra) # 800040c0 <stati>
    iunlock(f->ip);
    80004dca:	6c88                	ld	a0,24(s1)
    80004dcc:	fffff097          	auipc	ra,0xfffff
    80004dd0:	12c080e7          	jalr	300(ra) # 80003ef8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004dd4:	46e1                	li	a3,24
    80004dd6:	fb840613          	addi	a2,s0,-72
    80004dda:	85ce                	mv	a1,s3
    80004ddc:	05093503          	ld	a0,80(s2)
    80004de0:	ffffd097          	auipc	ra,0xffffd
    80004de4:	914080e7          	jalr	-1772(ra) # 800016f4 <copyout>
    80004de8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004dec:	60a6                	ld	ra,72(sp)
    80004dee:	6406                	ld	s0,64(sp)
    80004df0:	74e2                	ld	s1,56(sp)
    80004df2:	7942                	ld	s2,48(sp)
    80004df4:	79a2                	ld	s3,40(sp)
    80004df6:	6161                	addi	sp,sp,80
    80004df8:	8082                	ret
  return -1;
    80004dfa:	557d                	li	a0,-1
    80004dfc:	bfc5                	j	80004dec <filestat+0x60>

0000000080004dfe <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004dfe:	7179                	addi	sp,sp,-48
    80004e00:	f406                	sd	ra,40(sp)
    80004e02:	f022                	sd	s0,32(sp)
    80004e04:	ec26                	sd	s1,24(sp)
    80004e06:	e84a                	sd	s2,16(sp)
    80004e08:	e44e                	sd	s3,8(sp)
    80004e0a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004e0c:	00854783          	lbu	a5,8(a0)
    80004e10:	c3d5                	beqz	a5,80004eb4 <fileread+0xb6>
    80004e12:	84aa                	mv	s1,a0
    80004e14:	89ae                	mv	s3,a1
    80004e16:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e18:	411c                	lw	a5,0(a0)
    80004e1a:	4705                	li	a4,1
    80004e1c:	04e78963          	beq	a5,a4,80004e6e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e20:	470d                	li	a4,3
    80004e22:	04e78d63          	beq	a5,a4,80004e7c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e26:	4709                	li	a4,2
    80004e28:	06e79e63          	bne	a5,a4,80004ea4 <fileread+0xa6>
    ilock(f->ip);
    80004e2c:	6d08                	ld	a0,24(a0)
    80004e2e:	fffff097          	auipc	ra,0xfffff
    80004e32:	008080e7          	jalr	8(ra) # 80003e36 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e36:	874a                	mv	a4,s2
    80004e38:	5094                	lw	a3,32(s1)
    80004e3a:	864e                	mv	a2,s3
    80004e3c:	4585                	li	a1,1
    80004e3e:	6c88                	ld	a0,24(s1)
    80004e40:	fffff097          	auipc	ra,0xfffff
    80004e44:	2aa080e7          	jalr	682(ra) # 800040ea <readi>
    80004e48:	892a                	mv	s2,a0
    80004e4a:	00a05563          	blez	a0,80004e54 <fileread+0x56>
      f->off += r;
    80004e4e:	509c                	lw	a5,32(s1)
    80004e50:	9fa9                	addw	a5,a5,a0
    80004e52:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e54:	6c88                	ld	a0,24(s1)
    80004e56:	fffff097          	auipc	ra,0xfffff
    80004e5a:	0a2080e7          	jalr	162(ra) # 80003ef8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e5e:	854a                	mv	a0,s2
    80004e60:	70a2                	ld	ra,40(sp)
    80004e62:	7402                	ld	s0,32(sp)
    80004e64:	64e2                	ld	s1,24(sp)
    80004e66:	6942                	ld	s2,16(sp)
    80004e68:	69a2                	ld	s3,8(sp)
    80004e6a:	6145                	addi	sp,sp,48
    80004e6c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e6e:	6908                	ld	a0,16(a0)
    80004e70:	00000097          	auipc	ra,0x0
    80004e74:	3c6080e7          	jalr	966(ra) # 80005236 <piperead>
    80004e78:	892a                	mv	s2,a0
    80004e7a:	b7d5                	j	80004e5e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e7c:	02451783          	lh	a5,36(a0)
    80004e80:	03079693          	slli	a3,a5,0x30
    80004e84:	92c1                	srli	a3,a3,0x30
    80004e86:	4725                	li	a4,9
    80004e88:	02d76863          	bltu	a4,a3,80004eb8 <fileread+0xba>
    80004e8c:	0792                	slli	a5,a5,0x4
    80004e8e:	0023d717          	auipc	a4,0x23d
    80004e92:	95270713          	addi	a4,a4,-1710 # 802417e0 <devsw>
    80004e96:	97ba                	add	a5,a5,a4
    80004e98:	639c                	ld	a5,0(a5)
    80004e9a:	c38d                	beqz	a5,80004ebc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e9c:	4505                	li	a0,1
    80004e9e:	9782                	jalr	a5
    80004ea0:	892a                	mv	s2,a0
    80004ea2:	bf75                	j	80004e5e <fileread+0x60>
    panic("fileread");
    80004ea4:	00004517          	auipc	a0,0x4
    80004ea8:	81c50513          	addi	a0,a0,-2020 # 800086c0 <syscalls+0x270>
    80004eac:	ffffb097          	auipc	ra,0xffffb
    80004eb0:	692080e7          	jalr	1682(ra) # 8000053e <panic>
    return -1;
    80004eb4:	597d                	li	s2,-1
    80004eb6:	b765                	j	80004e5e <fileread+0x60>
      return -1;
    80004eb8:	597d                	li	s2,-1
    80004eba:	b755                	j	80004e5e <fileread+0x60>
    80004ebc:	597d                	li	s2,-1
    80004ebe:	b745                	j	80004e5e <fileread+0x60>

0000000080004ec0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ec0:	715d                	addi	sp,sp,-80
    80004ec2:	e486                	sd	ra,72(sp)
    80004ec4:	e0a2                	sd	s0,64(sp)
    80004ec6:	fc26                	sd	s1,56(sp)
    80004ec8:	f84a                	sd	s2,48(sp)
    80004eca:	f44e                	sd	s3,40(sp)
    80004ecc:	f052                	sd	s4,32(sp)
    80004ece:	ec56                	sd	s5,24(sp)
    80004ed0:	e85a                	sd	s6,16(sp)
    80004ed2:	e45e                	sd	s7,8(sp)
    80004ed4:	e062                	sd	s8,0(sp)
    80004ed6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ed8:	00954783          	lbu	a5,9(a0)
    80004edc:	10078663          	beqz	a5,80004fe8 <filewrite+0x128>
    80004ee0:	892a                	mv	s2,a0
    80004ee2:	8aae                	mv	s5,a1
    80004ee4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ee6:	411c                	lw	a5,0(a0)
    80004ee8:	4705                	li	a4,1
    80004eea:	02e78263          	beq	a5,a4,80004f0e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004eee:	470d                	li	a4,3
    80004ef0:	02e78663          	beq	a5,a4,80004f1c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ef4:	4709                	li	a4,2
    80004ef6:	0ee79163          	bne	a5,a4,80004fd8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004efa:	0ac05d63          	blez	a2,80004fb4 <filewrite+0xf4>
    int i = 0;
    80004efe:	4981                	li	s3,0
    80004f00:	6b05                	lui	s6,0x1
    80004f02:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004f06:	6b85                	lui	s7,0x1
    80004f08:	c00b8b9b          	addiw	s7,s7,-1024
    80004f0c:	a861                	j	80004fa4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004f0e:	6908                	ld	a0,16(a0)
    80004f10:	00000097          	auipc	ra,0x0
    80004f14:	22e080e7          	jalr	558(ra) # 8000513e <pipewrite>
    80004f18:	8a2a                	mv	s4,a0
    80004f1a:	a045                	j	80004fba <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f1c:	02451783          	lh	a5,36(a0)
    80004f20:	03079693          	slli	a3,a5,0x30
    80004f24:	92c1                	srli	a3,a3,0x30
    80004f26:	4725                	li	a4,9
    80004f28:	0cd76263          	bltu	a4,a3,80004fec <filewrite+0x12c>
    80004f2c:	0792                	slli	a5,a5,0x4
    80004f2e:	0023d717          	auipc	a4,0x23d
    80004f32:	8b270713          	addi	a4,a4,-1870 # 802417e0 <devsw>
    80004f36:	97ba                	add	a5,a5,a4
    80004f38:	679c                	ld	a5,8(a5)
    80004f3a:	cbdd                	beqz	a5,80004ff0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004f3c:	4505                	li	a0,1
    80004f3e:	9782                	jalr	a5
    80004f40:	8a2a                	mv	s4,a0
    80004f42:	a8a5                	j	80004fba <filewrite+0xfa>
    80004f44:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f48:	00000097          	auipc	ra,0x0
    80004f4c:	8b0080e7          	jalr	-1872(ra) # 800047f8 <begin_op>
      ilock(f->ip);
    80004f50:	01893503          	ld	a0,24(s2)
    80004f54:	fffff097          	auipc	ra,0xfffff
    80004f58:	ee2080e7          	jalr	-286(ra) # 80003e36 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f5c:	8762                	mv	a4,s8
    80004f5e:	02092683          	lw	a3,32(s2)
    80004f62:	01598633          	add	a2,s3,s5
    80004f66:	4585                	li	a1,1
    80004f68:	01893503          	ld	a0,24(s2)
    80004f6c:	fffff097          	auipc	ra,0xfffff
    80004f70:	276080e7          	jalr	630(ra) # 800041e2 <writei>
    80004f74:	84aa                	mv	s1,a0
    80004f76:	00a05763          	blez	a0,80004f84 <filewrite+0xc4>
        f->off += r;
    80004f7a:	02092783          	lw	a5,32(s2)
    80004f7e:	9fa9                	addw	a5,a5,a0
    80004f80:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f84:	01893503          	ld	a0,24(s2)
    80004f88:	fffff097          	auipc	ra,0xfffff
    80004f8c:	f70080e7          	jalr	-144(ra) # 80003ef8 <iunlock>
      end_op();
    80004f90:	00000097          	auipc	ra,0x0
    80004f94:	8e8080e7          	jalr	-1816(ra) # 80004878 <end_op>

      if(r != n1){
    80004f98:	009c1f63          	bne	s8,s1,80004fb6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f9c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004fa0:	0149db63          	bge	s3,s4,80004fb6 <filewrite+0xf6>
      int n1 = n - i;
    80004fa4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004fa8:	84be                	mv	s1,a5
    80004faa:	2781                	sext.w	a5,a5
    80004fac:	f8fb5ce3          	bge	s6,a5,80004f44 <filewrite+0x84>
    80004fb0:	84de                	mv	s1,s7
    80004fb2:	bf49                	j	80004f44 <filewrite+0x84>
    int i = 0;
    80004fb4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004fb6:	013a1f63          	bne	s4,s3,80004fd4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004fba:	8552                	mv	a0,s4
    80004fbc:	60a6                	ld	ra,72(sp)
    80004fbe:	6406                	ld	s0,64(sp)
    80004fc0:	74e2                	ld	s1,56(sp)
    80004fc2:	7942                	ld	s2,48(sp)
    80004fc4:	79a2                	ld	s3,40(sp)
    80004fc6:	7a02                	ld	s4,32(sp)
    80004fc8:	6ae2                	ld	s5,24(sp)
    80004fca:	6b42                	ld	s6,16(sp)
    80004fcc:	6ba2                	ld	s7,8(sp)
    80004fce:	6c02                	ld	s8,0(sp)
    80004fd0:	6161                	addi	sp,sp,80
    80004fd2:	8082                	ret
    ret = (i == n ? n : -1);
    80004fd4:	5a7d                	li	s4,-1
    80004fd6:	b7d5                	j	80004fba <filewrite+0xfa>
    panic("filewrite");
    80004fd8:	00003517          	auipc	a0,0x3
    80004fdc:	6f850513          	addi	a0,a0,1784 # 800086d0 <syscalls+0x280>
    80004fe0:	ffffb097          	auipc	ra,0xffffb
    80004fe4:	55e080e7          	jalr	1374(ra) # 8000053e <panic>
    return -1;
    80004fe8:	5a7d                	li	s4,-1
    80004fea:	bfc1                	j	80004fba <filewrite+0xfa>
      return -1;
    80004fec:	5a7d                	li	s4,-1
    80004fee:	b7f1                	j	80004fba <filewrite+0xfa>
    80004ff0:	5a7d                	li	s4,-1
    80004ff2:	b7e1                	j	80004fba <filewrite+0xfa>

0000000080004ff4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ff4:	7179                	addi	sp,sp,-48
    80004ff6:	f406                	sd	ra,40(sp)
    80004ff8:	f022                	sd	s0,32(sp)
    80004ffa:	ec26                	sd	s1,24(sp)
    80004ffc:	e84a                	sd	s2,16(sp)
    80004ffe:	e44e                	sd	s3,8(sp)
    80005000:	e052                	sd	s4,0(sp)
    80005002:	1800                	addi	s0,sp,48
    80005004:	84aa                	mv	s1,a0
    80005006:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005008:	0005b023          	sd	zero,0(a1)
    8000500c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005010:	00000097          	auipc	ra,0x0
    80005014:	bf8080e7          	jalr	-1032(ra) # 80004c08 <filealloc>
    80005018:	e088                	sd	a0,0(s1)
    8000501a:	c551                	beqz	a0,800050a6 <pipealloc+0xb2>
    8000501c:	00000097          	auipc	ra,0x0
    80005020:	bec080e7          	jalr	-1044(ra) # 80004c08 <filealloc>
    80005024:	00aa3023          	sd	a0,0(s4)
    80005028:	c92d                	beqz	a0,8000509a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000502a:	ffffc097          	auipc	ra,0xffffc
    8000502e:	b02080e7          	jalr	-1278(ra) # 80000b2c <kalloc>
    80005032:	892a                	mv	s2,a0
    80005034:	c125                	beqz	a0,80005094 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005036:	4985                	li	s3,1
    80005038:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000503c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005040:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005044:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005048:	00003597          	auipc	a1,0x3
    8000504c:	69858593          	addi	a1,a1,1688 # 800086e0 <syscalls+0x290>
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	b5c080e7          	jalr	-1188(ra) # 80000bac <initlock>
  (*f0)->type = FD_PIPE;
    80005058:	609c                	ld	a5,0(s1)
    8000505a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000505e:	609c                	ld	a5,0(s1)
    80005060:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005064:	609c                	ld	a5,0(s1)
    80005066:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000506a:	609c                	ld	a5,0(s1)
    8000506c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005070:	000a3783          	ld	a5,0(s4)
    80005074:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005078:	000a3783          	ld	a5,0(s4)
    8000507c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005080:	000a3783          	ld	a5,0(s4)
    80005084:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005088:	000a3783          	ld	a5,0(s4)
    8000508c:	0127b823          	sd	s2,16(a5)
  return 0;
    80005090:	4501                	li	a0,0
    80005092:	a025                	j	800050ba <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005094:	6088                	ld	a0,0(s1)
    80005096:	e501                	bnez	a0,8000509e <pipealloc+0xaa>
    80005098:	a039                	j	800050a6 <pipealloc+0xb2>
    8000509a:	6088                	ld	a0,0(s1)
    8000509c:	c51d                	beqz	a0,800050ca <pipealloc+0xd6>
    fileclose(*f0);
    8000509e:	00000097          	auipc	ra,0x0
    800050a2:	c26080e7          	jalr	-986(ra) # 80004cc4 <fileclose>
  if(*f1)
    800050a6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800050aa:	557d                	li	a0,-1
  if(*f1)
    800050ac:	c799                	beqz	a5,800050ba <pipealloc+0xc6>
    fileclose(*f1);
    800050ae:	853e                	mv	a0,a5
    800050b0:	00000097          	auipc	ra,0x0
    800050b4:	c14080e7          	jalr	-1004(ra) # 80004cc4 <fileclose>
  return -1;
    800050b8:	557d                	li	a0,-1
}
    800050ba:	70a2                	ld	ra,40(sp)
    800050bc:	7402                	ld	s0,32(sp)
    800050be:	64e2                	ld	s1,24(sp)
    800050c0:	6942                	ld	s2,16(sp)
    800050c2:	69a2                	ld	s3,8(sp)
    800050c4:	6a02                	ld	s4,0(sp)
    800050c6:	6145                	addi	sp,sp,48
    800050c8:	8082                	ret
  return -1;
    800050ca:	557d                	li	a0,-1
    800050cc:	b7fd                	j	800050ba <pipealloc+0xc6>

00000000800050ce <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800050ce:	1101                	addi	sp,sp,-32
    800050d0:	ec06                	sd	ra,24(sp)
    800050d2:	e822                	sd	s0,16(sp)
    800050d4:	e426                	sd	s1,8(sp)
    800050d6:	e04a                	sd	s2,0(sp)
    800050d8:	1000                	addi	s0,sp,32
    800050da:	84aa                	mv	s1,a0
    800050dc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800050de:	ffffc097          	auipc	ra,0xffffc
    800050e2:	b5e080e7          	jalr	-1186(ra) # 80000c3c <acquire>
  if(writable){
    800050e6:	02090d63          	beqz	s2,80005120 <pipeclose+0x52>
    pi->writeopen = 0;
    800050ea:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800050ee:	21848513          	addi	a0,s1,536
    800050f2:	ffffd097          	auipc	ra,0xffffd
    800050f6:	464080e7          	jalr	1124(ra) # 80002556 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800050fa:	2204b783          	ld	a5,544(s1)
    800050fe:	eb95                	bnez	a5,80005132 <pipeclose+0x64>
    release(&pi->lock);
    80005100:	8526                	mv	a0,s1
    80005102:	ffffc097          	auipc	ra,0xffffc
    80005106:	bee080e7          	jalr	-1042(ra) # 80000cf0 <release>
    kfree((char*)pi);
    8000510a:	8526                	mv	a0,s1
    8000510c:	ffffc097          	auipc	ra,0xffffc
    80005110:	8de080e7          	jalr	-1826(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80005114:	60e2                	ld	ra,24(sp)
    80005116:	6442                	ld	s0,16(sp)
    80005118:	64a2                	ld	s1,8(sp)
    8000511a:	6902                	ld	s2,0(sp)
    8000511c:	6105                	addi	sp,sp,32
    8000511e:	8082                	ret
    pi->readopen = 0;
    80005120:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005124:	21c48513          	addi	a0,s1,540
    80005128:	ffffd097          	auipc	ra,0xffffd
    8000512c:	42e080e7          	jalr	1070(ra) # 80002556 <wakeup>
    80005130:	b7e9                	j	800050fa <pipeclose+0x2c>
    release(&pi->lock);
    80005132:	8526                	mv	a0,s1
    80005134:	ffffc097          	auipc	ra,0xffffc
    80005138:	bbc080e7          	jalr	-1092(ra) # 80000cf0 <release>
}
    8000513c:	bfe1                	j	80005114 <pipeclose+0x46>

000000008000513e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000513e:	711d                	addi	sp,sp,-96
    80005140:	ec86                	sd	ra,88(sp)
    80005142:	e8a2                	sd	s0,80(sp)
    80005144:	e4a6                	sd	s1,72(sp)
    80005146:	e0ca                	sd	s2,64(sp)
    80005148:	fc4e                	sd	s3,56(sp)
    8000514a:	f852                	sd	s4,48(sp)
    8000514c:	f456                	sd	s5,40(sp)
    8000514e:	f05a                	sd	s6,32(sp)
    80005150:	ec5e                	sd	s7,24(sp)
    80005152:	e862                	sd	s8,16(sp)
    80005154:	1080                	addi	s0,sp,96
    80005156:	84aa                	mv	s1,a0
    80005158:	8aae                	mv	s5,a1
    8000515a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000515c:	ffffd097          	auipc	ra,0xffffd
    80005160:	970080e7          	jalr	-1680(ra) # 80001acc <myproc>
    80005164:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005166:	8526                	mv	a0,s1
    80005168:	ffffc097          	auipc	ra,0xffffc
    8000516c:	ad4080e7          	jalr	-1324(ra) # 80000c3c <acquire>
  while(i < n){
    80005170:	0b405663          	blez	s4,8000521c <pipewrite+0xde>
  int i = 0;
    80005174:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005176:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005178:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000517c:	21c48b93          	addi	s7,s1,540
    80005180:	a089                	j	800051c2 <pipewrite+0x84>
      release(&pi->lock);
    80005182:	8526                	mv	a0,s1
    80005184:	ffffc097          	auipc	ra,0xffffc
    80005188:	b6c080e7          	jalr	-1172(ra) # 80000cf0 <release>
      return -1;
    8000518c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000518e:	854a                	mv	a0,s2
    80005190:	60e6                	ld	ra,88(sp)
    80005192:	6446                	ld	s0,80(sp)
    80005194:	64a6                	ld	s1,72(sp)
    80005196:	6906                	ld	s2,64(sp)
    80005198:	79e2                	ld	s3,56(sp)
    8000519a:	7a42                	ld	s4,48(sp)
    8000519c:	7aa2                	ld	s5,40(sp)
    8000519e:	7b02                	ld	s6,32(sp)
    800051a0:	6be2                	ld	s7,24(sp)
    800051a2:	6c42                	ld	s8,16(sp)
    800051a4:	6125                	addi	sp,sp,96
    800051a6:	8082                	ret
      wakeup(&pi->nread);
    800051a8:	8562                	mv	a0,s8
    800051aa:	ffffd097          	auipc	ra,0xffffd
    800051ae:	3ac080e7          	jalr	940(ra) # 80002556 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800051b2:	85a6                	mv	a1,s1
    800051b4:	855e                	mv	a0,s7
    800051b6:	ffffd097          	auipc	ra,0xffffd
    800051ba:	33c080e7          	jalr	828(ra) # 800024f2 <sleep>
  while(i < n){
    800051be:	07495063          	bge	s2,s4,8000521e <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800051c2:	2204a783          	lw	a5,544(s1)
    800051c6:	dfd5                	beqz	a5,80005182 <pipewrite+0x44>
    800051c8:	854e                	mv	a0,s3
    800051ca:	ffffd097          	auipc	ra,0xffffd
    800051ce:	5dc080e7          	jalr	1500(ra) # 800027a6 <killed>
    800051d2:	f945                	bnez	a0,80005182 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800051d4:	2184a783          	lw	a5,536(s1)
    800051d8:	21c4a703          	lw	a4,540(s1)
    800051dc:	2007879b          	addiw	a5,a5,512
    800051e0:	fcf704e3          	beq	a4,a5,800051a8 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051e4:	4685                	li	a3,1
    800051e6:	01590633          	add	a2,s2,s5
    800051ea:	faf40593          	addi	a1,s0,-81
    800051ee:	0509b503          	ld	a0,80(s3)
    800051f2:	ffffc097          	auipc	ra,0xffffc
    800051f6:	622080e7          	jalr	1570(ra) # 80001814 <copyin>
    800051fa:	03650263          	beq	a0,s6,8000521e <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800051fe:	21c4a783          	lw	a5,540(s1)
    80005202:	0017871b          	addiw	a4,a5,1
    80005206:	20e4ae23          	sw	a4,540(s1)
    8000520a:	1ff7f793          	andi	a5,a5,511
    8000520e:	97a6                	add	a5,a5,s1
    80005210:	faf44703          	lbu	a4,-81(s0)
    80005214:	00e78c23          	sb	a4,24(a5)
      i++;
    80005218:	2905                	addiw	s2,s2,1
    8000521a:	b755                	j	800051be <pipewrite+0x80>
  int i = 0;
    8000521c:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000521e:	21848513          	addi	a0,s1,536
    80005222:	ffffd097          	auipc	ra,0xffffd
    80005226:	334080e7          	jalr	820(ra) # 80002556 <wakeup>
  release(&pi->lock);
    8000522a:	8526                	mv	a0,s1
    8000522c:	ffffc097          	auipc	ra,0xffffc
    80005230:	ac4080e7          	jalr	-1340(ra) # 80000cf0 <release>
  return i;
    80005234:	bfa9                	j	8000518e <pipewrite+0x50>

0000000080005236 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005236:	715d                	addi	sp,sp,-80
    80005238:	e486                	sd	ra,72(sp)
    8000523a:	e0a2                	sd	s0,64(sp)
    8000523c:	fc26                	sd	s1,56(sp)
    8000523e:	f84a                	sd	s2,48(sp)
    80005240:	f44e                	sd	s3,40(sp)
    80005242:	f052                	sd	s4,32(sp)
    80005244:	ec56                	sd	s5,24(sp)
    80005246:	e85a                	sd	s6,16(sp)
    80005248:	0880                	addi	s0,sp,80
    8000524a:	84aa                	mv	s1,a0
    8000524c:	892e                	mv	s2,a1
    8000524e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005250:	ffffd097          	auipc	ra,0xffffd
    80005254:	87c080e7          	jalr	-1924(ra) # 80001acc <myproc>
    80005258:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000525a:	8526                	mv	a0,s1
    8000525c:	ffffc097          	auipc	ra,0xffffc
    80005260:	9e0080e7          	jalr	-1568(ra) # 80000c3c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005264:	2184a703          	lw	a4,536(s1)
    80005268:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000526c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005270:	02f71763          	bne	a4,a5,8000529e <piperead+0x68>
    80005274:	2244a783          	lw	a5,548(s1)
    80005278:	c39d                	beqz	a5,8000529e <piperead+0x68>
    if(killed(pr)){
    8000527a:	8552                	mv	a0,s4
    8000527c:	ffffd097          	auipc	ra,0xffffd
    80005280:	52a080e7          	jalr	1322(ra) # 800027a6 <killed>
    80005284:	e941                	bnez	a0,80005314 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005286:	85a6                	mv	a1,s1
    80005288:	854e                	mv	a0,s3
    8000528a:	ffffd097          	auipc	ra,0xffffd
    8000528e:	268080e7          	jalr	616(ra) # 800024f2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005292:	2184a703          	lw	a4,536(s1)
    80005296:	21c4a783          	lw	a5,540(s1)
    8000529a:	fcf70de3          	beq	a4,a5,80005274 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000529e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052a0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052a2:	05505363          	blez	s5,800052e8 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    800052a6:	2184a783          	lw	a5,536(s1)
    800052aa:	21c4a703          	lw	a4,540(s1)
    800052ae:	02f70d63          	beq	a4,a5,800052e8 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800052b2:	0017871b          	addiw	a4,a5,1
    800052b6:	20e4ac23          	sw	a4,536(s1)
    800052ba:	1ff7f793          	andi	a5,a5,511
    800052be:	97a6                	add	a5,a5,s1
    800052c0:	0187c783          	lbu	a5,24(a5)
    800052c4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052c8:	4685                	li	a3,1
    800052ca:	fbf40613          	addi	a2,s0,-65
    800052ce:	85ca                	mv	a1,s2
    800052d0:	050a3503          	ld	a0,80(s4)
    800052d4:	ffffc097          	auipc	ra,0xffffc
    800052d8:	420080e7          	jalr	1056(ra) # 800016f4 <copyout>
    800052dc:	01650663          	beq	a0,s6,800052e8 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052e0:	2985                	addiw	s3,s3,1
    800052e2:	0905                	addi	s2,s2,1
    800052e4:	fd3a91e3          	bne	s5,s3,800052a6 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800052e8:	21c48513          	addi	a0,s1,540
    800052ec:	ffffd097          	auipc	ra,0xffffd
    800052f0:	26a080e7          	jalr	618(ra) # 80002556 <wakeup>
  release(&pi->lock);
    800052f4:	8526                	mv	a0,s1
    800052f6:	ffffc097          	auipc	ra,0xffffc
    800052fa:	9fa080e7          	jalr	-1542(ra) # 80000cf0 <release>
  return i;
}
    800052fe:	854e                	mv	a0,s3
    80005300:	60a6                	ld	ra,72(sp)
    80005302:	6406                	ld	s0,64(sp)
    80005304:	74e2                	ld	s1,56(sp)
    80005306:	7942                	ld	s2,48(sp)
    80005308:	79a2                	ld	s3,40(sp)
    8000530a:	7a02                	ld	s4,32(sp)
    8000530c:	6ae2                	ld	s5,24(sp)
    8000530e:	6b42                	ld	s6,16(sp)
    80005310:	6161                	addi	sp,sp,80
    80005312:	8082                	ret
      release(&pi->lock);
    80005314:	8526                	mv	a0,s1
    80005316:	ffffc097          	auipc	ra,0xffffc
    8000531a:	9da080e7          	jalr	-1574(ra) # 80000cf0 <release>
      return -1;
    8000531e:	59fd                	li	s3,-1
    80005320:	bff9                	j	800052fe <piperead+0xc8>

0000000080005322 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005322:	1141                	addi	sp,sp,-16
    80005324:	e422                	sd	s0,8(sp)
    80005326:	0800                	addi	s0,sp,16
    80005328:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000532a:	8905                	andi	a0,a0,1
    8000532c:	c111                	beqz	a0,80005330 <flags2perm+0xe>
      perm = PTE_X;
    8000532e:	4521                	li	a0,8
    if(flags & 0x2)
    80005330:	8b89                	andi	a5,a5,2
    80005332:	c399                	beqz	a5,80005338 <flags2perm+0x16>
      perm |= PTE_W;
    80005334:	00456513          	ori	a0,a0,4
    return perm;
}
    80005338:	6422                	ld	s0,8(sp)
    8000533a:	0141                	addi	sp,sp,16
    8000533c:	8082                	ret

000000008000533e <exec>:

int
exec(char *path, char **argv)
{
    8000533e:	de010113          	addi	sp,sp,-544
    80005342:	20113c23          	sd	ra,536(sp)
    80005346:	20813823          	sd	s0,528(sp)
    8000534a:	20913423          	sd	s1,520(sp)
    8000534e:	21213023          	sd	s2,512(sp)
    80005352:	ffce                	sd	s3,504(sp)
    80005354:	fbd2                	sd	s4,496(sp)
    80005356:	f7d6                	sd	s5,488(sp)
    80005358:	f3da                	sd	s6,480(sp)
    8000535a:	efde                	sd	s7,472(sp)
    8000535c:	ebe2                	sd	s8,464(sp)
    8000535e:	e7e6                	sd	s9,456(sp)
    80005360:	e3ea                	sd	s10,448(sp)
    80005362:	ff6e                	sd	s11,440(sp)
    80005364:	1400                	addi	s0,sp,544
    80005366:	892a                	mv	s2,a0
    80005368:	dea43423          	sd	a0,-536(s0)
    8000536c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005370:	ffffc097          	auipc	ra,0xffffc
    80005374:	75c080e7          	jalr	1884(ra) # 80001acc <myproc>
    80005378:	84aa                	mv	s1,a0

  begin_op();
    8000537a:	fffff097          	auipc	ra,0xfffff
    8000537e:	47e080e7          	jalr	1150(ra) # 800047f8 <begin_op>

  if((ip = namei(path)) == 0){
    80005382:	854a                	mv	a0,s2
    80005384:	fffff097          	auipc	ra,0xfffff
    80005388:	258080e7          	jalr	600(ra) # 800045dc <namei>
    8000538c:	c93d                	beqz	a0,80005402 <exec+0xc4>
    8000538e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	aa6080e7          	jalr	-1370(ra) # 80003e36 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005398:	04000713          	li	a4,64
    8000539c:	4681                	li	a3,0
    8000539e:	e5040613          	addi	a2,s0,-432
    800053a2:	4581                	li	a1,0
    800053a4:	8556                	mv	a0,s5
    800053a6:	fffff097          	auipc	ra,0xfffff
    800053aa:	d44080e7          	jalr	-700(ra) # 800040ea <readi>
    800053ae:	04000793          	li	a5,64
    800053b2:	00f51a63          	bne	a0,a5,800053c6 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800053b6:	e5042703          	lw	a4,-432(s0)
    800053ba:	464c47b7          	lui	a5,0x464c4
    800053be:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800053c2:	04f70663          	beq	a4,a5,8000540e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800053c6:	8556                	mv	a0,s5
    800053c8:	fffff097          	auipc	ra,0xfffff
    800053cc:	cd0080e7          	jalr	-816(ra) # 80004098 <iunlockput>
    end_op();
    800053d0:	fffff097          	auipc	ra,0xfffff
    800053d4:	4a8080e7          	jalr	1192(ra) # 80004878 <end_op>
  }
  return -1;
    800053d8:	557d                	li	a0,-1
}
    800053da:	21813083          	ld	ra,536(sp)
    800053de:	21013403          	ld	s0,528(sp)
    800053e2:	20813483          	ld	s1,520(sp)
    800053e6:	20013903          	ld	s2,512(sp)
    800053ea:	79fe                	ld	s3,504(sp)
    800053ec:	7a5e                	ld	s4,496(sp)
    800053ee:	7abe                	ld	s5,488(sp)
    800053f0:	7b1e                	ld	s6,480(sp)
    800053f2:	6bfe                	ld	s7,472(sp)
    800053f4:	6c5e                	ld	s8,464(sp)
    800053f6:	6cbe                	ld	s9,456(sp)
    800053f8:	6d1e                	ld	s10,448(sp)
    800053fa:	7dfa                	ld	s11,440(sp)
    800053fc:	22010113          	addi	sp,sp,544
    80005400:	8082                	ret
    end_op();
    80005402:	fffff097          	auipc	ra,0xfffff
    80005406:	476080e7          	jalr	1142(ra) # 80004878 <end_op>
    return -1;
    8000540a:	557d                	li	a0,-1
    8000540c:	b7f9                	j	800053da <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000540e:	8526                	mv	a0,s1
    80005410:	ffffc097          	auipc	ra,0xffffc
    80005414:	780080e7          	jalr	1920(ra) # 80001b90 <proc_pagetable>
    80005418:	8b2a                	mv	s6,a0
    8000541a:	d555                	beqz	a0,800053c6 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000541c:	e7042783          	lw	a5,-400(s0)
    80005420:	e8845703          	lhu	a4,-376(s0)
    80005424:	c735                	beqz	a4,80005490 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005426:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005428:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000542c:	6a05                	lui	s4,0x1
    8000542e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005432:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005436:	6d85                	lui	s11,0x1
    80005438:	7d7d                	lui	s10,0xfffff
    8000543a:	a481                	j	8000567a <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000543c:	00003517          	auipc	a0,0x3
    80005440:	2ac50513          	addi	a0,a0,684 # 800086e8 <syscalls+0x298>
    80005444:	ffffb097          	auipc	ra,0xffffb
    80005448:	0fa080e7          	jalr	250(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000544c:	874a                	mv	a4,s2
    8000544e:	009c86bb          	addw	a3,s9,s1
    80005452:	4581                	li	a1,0
    80005454:	8556                	mv	a0,s5
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	c94080e7          	jalr	-876(ra) # 800040ea <readi>
    8000545e:	2501                	sext.w	a0,a0
    80005460:	1aa91a63          	bne	s2,a0,80005614 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80005464:	009d84bb          	addw	s1,s11,s1
    80005468:	013d09bb          	addw	s3,s10,s3
    8000546c:	1f74f763          	bgeu	s1,s7,8000565a <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80005470:	02049593          	slli	a1,s1,0x20
    80005474:	9181                	srli	a1,a1,0x20
    80005476:	95e2                	add	a1,a1,s8
    80005478:	855a                	mv	a0,s6
    8000547a:	ffffc097          	auipc	ra,0xffffc
    8000547e:	c48080e7          	jalr	-952(ra) # 800010c2 <walkaddr>
    80005482:	862a                	mv	a2,a0
    if(pa == 0)
    80005484:	dd45                	beqz	a0,8000543c <exec+0xfe>
      n = PGSIZE;
    80005486:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005488:	fd49f2e3          	bgeu	s3,s4,8000544c <exec+0x10e>
      n = sz - i;
    8000548c:	894e                	mv	s2,s3
    8000548e:	bf7d                	j	8000544c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005490:	4901                	li	s2,0
  iunlockput(ip);
    80005492:	8556                	mv	a0,s5
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	c04080e7          	jalr	-1020(ra) # 80004098 <iunlockput>
  end_op();
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	3dc080e7          	jalr	988(ra) # 80004878 <end_op>
  p = myproc();
    800054a4:	ffffc097          	auipc	ra,0xffffc
    800054a8:	628080e7          	jalr	1576(ra) # 80001acc <myproc>
    800054ac:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800054ae:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800054b2:	6785                	lui	a5,0x1
    800054b4:	17fd                	addi	a5,a5,-1
    800054b6:	993e                	add	s2,s2,a5
    800054b8:	77fd                	lui	a5,0xfffff
    800054ba:	00f977b3          	and	a5,s2,a5
    800054be:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800054c2:	4691                	li	a3,4
    800054c4:	6609                	lui	a2,0x2
    800054c6:	963e                	add	a2,a2,a5
    800054c8:	85be                	mv	a1,a5
    800054ca:	855a                	mv	a0,s6
    800054cc:	ffffc097          	auipc	ra,0xffffc
    800054d0:	faa080e7          	jalr	-86(ra) # 80001476 <uvmalloc>
    800054d4:	8c2a                	mv	s8,a0
  ip = 0;
    800054d6:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800054d8:	12050e63          	beqz	a0,80005614 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800054dc:	75f9                	lui	a1,0xffffe
    800054de:	95aa                	add	a1,a1,a0
    800054e0:	855a                	mv	a0,s6
    800054e2:	ffffc097          	auipc	ra,0xffffc
    800054e6:	1e0080e7          	jalr	480(ra) # 800016c2 <uvmclear>
  stackbase = sp - PGSIZE;
    800054ea:	7afd                	lui	s5,0xfffff
    800054ec:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800054ee:	df043783          	ld	a5,-528(s0)
    800054f2:	6388                	ld	a0,0(a5)
    800054f4:	c925                	beqz	a0,80005564 <exec+0x226>
    800054f6:	e9040993          	addi	s3,s0,-368
    800054fa:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800054fe:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005500:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005502:	ffffc097          	auipc	ra,0xffffc
    80005506:	9b2080e7          	jalr	-1614(ra) # 80000eb4 <strlen>
    8000550a:	0015079b          	addiw	a5,a0,1
    8000550e:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005512:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005516:	13596663          	bltu	s2,s5,80005642 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000551a:	df043d83          	ld	s11,-528(s0)
    8000551e:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005522:	8552                	mv	a0,s4
    80005524:	ffffc097          	auipc	ra,0xffffc
    80005528:	990080e7          	jalr	-1648(ra) # 80000eb4 <strlen>
    8000552c:	0015069b          	addiw	a3,a0,1
    80005530:	8652                	mv	a2,s4
    80005532:	85ca                	mv	a1,s2
    80005534:	855a                	mv	a0,s6
    80005536:	ffffc097          	auipc	ra,0xffffc
    8000553a:	1be080e7          	jalr	446(ra) # 800016f4 <copyout>
    8000553e:	10054663          	bltz	a0,8000564a <exec+0x30c>
    ustack[argc] = sp;
    80005542:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005546:	0485                	addi	s1,s1,1
    80005548:	008d8793          	addi	a5,s11,8
    8000554c:	def43823          	sd	a5,-528(s0)
    80005550:	008db503          	ld	a0,8(s11)
    80005554:	c911                	beqz	a0,80005568 <exec+0x22a>
    if(argc >= MAXARG)
    80005556:	09a1                	addi	s3,s3,8
    80005558:	fb3c95e3          	bne	s9,s3,80005502 <exec+0x1c4>
  sz = sz1;
    8000555c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005560:	4a81                	li	s5,0
    80005562:	a84d                	j	80005614 <exec+0x2d6>
  sp = sz;
    80005564:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005566:	4481                	li	s1,0
  ustack[argc] = 0;
    80005568:	00349793          	slli	a5,s1,0x3
    8000556c:	f9040713          	addi	a4,s0,-112
    80005570:	97ba                	add	a5,a5,a4
    80005572:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7fdbc588>
  sp -= (argc+1) * sizeof(uint64);
    80005576:	00148693          	addi	a3,s1,1
    8000557a:	068e                	slli	a3,a3,0x3
    8000557c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005580:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005584:	01597663          	bgeu	s2,s5,80005590 <exec+0x252>
  sz = sz1;
    80005588:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000558c:	4a81                	li	s5,0
    8000558e:	a059                	j	80005614 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005590:	e9040613          	addi	a2,s0,-368
    80005594:	85ca                	mv	a1,s2
    80005596:	855a                	mv	a0,s6
    80005598:	ffffc097          	auipc	ra,0xffffc
    8000559c:	15c080e7          	jalr	348(ra) # 800016f4 <copyout>
    800055a0:	0a054963          	bltz	a0,80005652 <exec+0x314>
  p->trapframe->a1 = sp;
    800055a4:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    800055a8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800055ac:	de843783          	ld	a5,-536(s0)
    800055b0:	0007c703          	lbu	a4,0(a5)
    800055b4:	cf11                	beqz	a4,800055d0 <exec+0x292>
    800055b6:	0785                	addi	a5,a5,1
    if(*s == '/')
    800055b8:	02f00693          	li	a3,47
    800055bc:	a039                	j	800055ca <exec+0x28c>
      last = s+1;
    800055be:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800055c2:	0785                	addi	a5,a5,1
    800055c4:	fff7c703          	lbu	a4,-1(a5)
    800055c8:	c701                	beqz	a4,800055d0 <exec+0x292>
    if(*s == '/')
    800055ca:	fed71ce3          	bne	a4,a3,800055c2 <exec+0x284>
    800055ce:	bfc5                	j	800055be <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    800055d0:	4641                	li	a2,16
    800055d2:	de843583          	ld	a1,-536(s0)
    800055d6:	158b8513          	addi	a0,s7,344
    800055da:	ffffc097          	auipc	ra,0xffffc
    800055de:	8a8080e7          	jalr	-1880(ra) # 80000e82 <safestrcpy>
  oldpagetable = p->pagetable;
    800055e2:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800055e6:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800055ea:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055ee:	058bb783          	ld	a5,88(s7)
    800055f2:	e6843703          	ld	a4,-408(s0)
    800055f6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055f8:	058bb783          	ld	a5,88(s7)
    800055fc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005600:	85ea                	mv	a1,s10
    80005602:	ffffc097          	auipc	ra,0xffffc
    80005606:	62a080e7          	jalr	1578(ra) # 80001c2c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000560a:	0004851b          	sext.w	a0,s1
    8000560e:	b3f1                	j	800053da <exec+0x9c>
    80005610:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005614:	df843583          	ld	a1,-520(s0)
    80005618:	855a                	mv	a0,s6
    8000561a:	ffffc097          	auipc	ra,0xffffc
    8000561e:	612080e7          	jalr	1554(ra) # 80001c2c <proc_freepagetable>
  if(ip){
    80005622:	da0a92e3          	bnez	s5,800053c6 <exec+0x88>
  return -1;
    80005626:	557d                	li	a0,-1
    80005628:	bb4d                	j	800053da <exec+0x9c>
    8000562a:	df243c23          	sd	s2,-520(s0)
    8000562e:	b7dd                	j	80005614 <exec+0x2d6>
    80005630:	df243c23          	sd	s2,-520(s0)
    80005634:	b7c5                	j	80005614 <exec+0x2d6>
    80005636:	df243c23          	sd	s2,-520(s0)
    8000563a:	bfe9                	j	80005614 <exec+0x2d6>
    8000563c:	df243c23          	sd	s2,-520(s0)
    80005640:	bfd1                	j	80005614 <exec+0x2d6>
  sz = sz1;
    80005642:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005646:	4a81                	li	s5,0
    80005648:	b7f1                	j	80005614 <exec+0x2d6>
  sz = sz1;
    8000564a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000564e:	4a81                	li	s5,0
    80005650:	b7d1                	j	80005614 <exec+0x2d6>
  sz = sz1;
    80005652:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005656:	4a81                	li	s5,0
    80005658:	bf75                	j	80005614 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000565a:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000565e:	e0843783          	ld	a5,-504(s0)
    80005662:	0017869b          	addiw	a3,a5,1
    80005666:	e0d43423          	sd	a3,-504(s0)
    8000566a:	e0043783          	ld	a5,-512(s0)
    8000566e:	0387879b          	addiw	a5,a5,56
    80005672:	e8845703          	lhu	a4,-376(s0)
    80005676:	e0e6dee3          	bge	a3,a4,80005492 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000567a:	2781                	sext.w	a5,a5
    8000567c:	e0f43023          	sd	a5,-512(s0)
    80005680:	03800713          	li	a4,56
    80005684:	86be                	mv	a3,a5
    80005686:	e1840613          	addi	a2,s0,-488
    8000568a:	4581                	li	a1,0
    8000568c:	8556                	mv	a0,s5
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	a5c080e7          	jalr	-1444(ra) # 800040ea <readi>
    80005696:	03800793          	li	a5,56
    8000569a:	f6f51be3          	bne	a0,a5,80005610 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    8000569e:	e1842783          	lw	a5,-488(s0)
    800056a2:	4705                	li	a4,1
    800056a4:	fae79de3          	bne	a5,a4,8000565e <exec+0x320>
    if(ph.memsz < ph.filesz)
    800056a8:	e4043483          	ld	s1,-448(s0)
    800056ac:	e3843783          	ld	a5,-456(s0)
    800056b0:	f6f4ede3          	bltu	s1,a5,8000562a <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800056b4:	e2843783          	ld	a5,-472(s0)
    800056b8:	94be                	add	s1,s1,a5
    800056ba:	f6f4ebe3          	bltu	s1,a5,80005630 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    800056be:	de043703          	ld	a4,-544(s0)
    800056c2:	8ff9                	and	a5,a5,a4
    800056c4:	fbad                	bnez	a5,80005636 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800056c6:	e1c42503          	lw	a0,-484(s0)
    800056ca:	00000097          	auipc	ra,0x0
    800056ce:	c58080e7          	jalr	-936(ra) # 80005322 <flags2perm>
    800056d2:	86aa                	mv	a3,a0
    800056d4:	8626                	mv	a2,s1
    800056d6:	85ca                	mv	a1,s2
    800056d8:	855a                	mv	a0,s6
    800056da:	ffffc097          	auipc	ra,0xffffc
    800056de:	d9c080e7          	jalr	-612(ra) # 80001476 <uvmalloc>
    800056e2:	dea43c23          	sd	a0,-520(s0)
    800056e6:	d939                	beqz	a0,8000563c <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800056e8:	e2843c03          	ld	s8,-472(s0)
    800056ec:	e2042c83          	lw	s9,-480(s0)
    800056f0:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800056f4:	f60b83e3          	beqz	s7,8000565a <exec+0x31c>
    800056f8:	89de                	mv	s3,s7
    800056fa:	4481                	li	s1,0
    800056fc:	bb95                	j	80005470 <exec+0x132>

00000000800056fe <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800056fe:	7179                	addi	sp,sp,-48
    80005700:	f406                	sd	ra,40(sp)
    80005702:	f022                	sd	s0,32(sp)
    80005704:	ec26                	sd	s1,24(sp)
    80005706:	e84a                	sd	s2,16(sp)
    80005708:	1800                	addi	s0,sp,48
    8000570a:	892e                	mv	s2,a1
    8000570c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000570e:	fdc40593          	addi	a1,s0,-36
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	b1c080e7          	jalr	-1252(ra) # 8000322e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000571a:	fdc42703          	lw	a4,-36(s0)
    8000571e:	47bd                	li	a5,15
    80005720:	02e7eb63          	bltu	a5,a4,80005756 <argfd+0x58>
    80005724:	ffffc097          	auipc	ra,0xffffc
    80005728:	3a8080e7          	jalr	936(ra) # 80001acc <myproc>
    8000572c:	fdc42703          	lw	a4,-36(s0)
    80005730:	01a70793          	addi	a5,a4,26
    80005734:	078e                	slli	a5,a5,0x3
    80005736:	953e                	add	a0,a0,a5
    80005738:	611c                	ld	a5,0(a0)
    8000573a:	c385                	beqz	a5,8000575a <argfd+0x5c>
    return -1;
  if(pfd)
    8000573c:	00090463          	beqz	s2,80005744 <argfd+0x46>
    *pfd = fd;
    80005740:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005744:	4501                	li	a0,0
  if(pf)
    80005746:	c091                	beqz	s1,8000574a <argfd+0x4c>
    *pf = f;
    80005748:	e09c                	sd	a5,0(s1)
}
    8000574a:	70a2                	ld	ra,40(sp)
    8000574c:	7402                	ld	s0,32(sp)
    8000574e:	64e2                	ld	s1,24(sp)
    80005750:	6942                	ld	s2,16(sp)
    80005752:	6145                	addi	sp,sp,48
    80005754:	8082                	ret
    return -1;
    80005756:	557d                	li	a0,-1
    80005758:	bfcd                	j	8000574a <argfd+0x4c>
    8000575a:	557d                	li	a0,-1
    8000575c:	b7fd                	j	8000574a <argfd+0x4c>

000000008000575e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000575e:	1101                	addi	sp,sp,-32
    80005760:	ec06                	sd	ra,24(sp)
    80005762:	e822                	sd	s0,16(sp)
    80005764:	e426                	sd	s1,8(sp)
    80005766:	1000                	addi	s0,sp,32
    80005768:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000576a:	ffffc097          	auipc	ra,0xffffc
    8000576e:	362080e7          	jalr	866(ra) # 80001acc <myproc>
    80005772:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005774:	0d050793          	addi	a5,a0,208
    80005778:	4501                	li	a0,0
    8000577a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000577c:	6398                	ld	a4,0(a5)
    8000577e:	cb19                	beqz	a4,80005794 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005780:	2505                	addiw	a0,a0,1
    80005782:	07a1                	addi	a5,a5,8
    80005784:	fed51ce3          	bne	a0,a3,8000577c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005788:	557d                	li	a0,-1
}
    8000578a:	60e2                	ld	ra,24(sp)
    8000578c:	6442                	ld	s0,16(sp)
    8000578e:	64a2                	ld	s1,8(sp)
    80005790:	6105                	addi	sp,sp,32
    80005792:	8082                	ret
      p->ofile[fd] = f;
    80005794:	01a50793          	addi	a5,a0,26
    80005798:	078e                	slli	a5,a5,0x3
    8000579a:	963e                	add	a2,a2,a5
    8000579c:	e204                	sd	s1,0(a2)
      return fd;
    8000579e:	b7f5                	j	8000578a <fdalloc+0x2c>

00000000800057a0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800057a0:	715d                	addi	sp,sp,-80
    800057a2:	e486                	sd	ra,72(sp)
    800057a4:	e0a2                	sd	s0,64(sp)
    800057a6:	fc26                	sd	s1,56(sp)
    800057a8:	f84a                	sd	s2,48(sp)
    800057aa:	f44e                	sd	s3,40(sp)
    800057ac:	f052                	sd	s4,32(sp)
    800057ae:	ec56                	sd	s5,24(sp)
    800057b0:	e85a                	sd	s6,16(sp)
    800057b2:	0880                	addi	s0,sp,80
    800057b4:	8b2e                	mv	s6,a1
    800057b6:	89b2                	mv	s3,a2
    800057b8:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800057ba:	fb040593          	addi	a1,s0,-80
    800057be:	fffff097          	auipc	ra,0xfffff
    800057c2:	e3c080e7          	jalr	-452(ra) # 800045fa <nameiparent>
    800057c6:	84aa                	mv	s1,a0
    800057c8:	14050f63          	beqz	a0,80005926 <create+0x186>
    return 0;

  ilock(dp);
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	66a080e7          	jalr	1642(ra) # 80003e36 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800057d4:	4601                	li	a2,0
    800057d6:	fb040593          	addi	a1,s0,-80
    800057da:	8526                	mv	a0,s1
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	b3e080e7          	jalr	-1218(ra) # 8000431a <dirlookup>
    800057e4:	8aaa                	mv	s5,a0
    800057e6:	c931                	beqz	a0,8000583a <create+0x9a>
    iunlockput(dp);
    800057e8:	8526                	mv	a0,s1
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	8ae080e7          	jalr	-1874(ra) # 80004098 <iunlockput>
    ilock(ip);
    800057f2:	8556                	mv	a0,s5
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	642080e7          	jalr	1602(ra) # 80003e36 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800057fc:	000b059b          	sext.w	a1,s6
    80005800:	4789                	li	a5,2
    80005802:	02f59563          	bne	a1,a5,8000582c <create+0x8c>
    80005806:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdbc6cc>
    8000580a:	37f9                	addiw	a5,a5,-2
    8000580c:	17c2                	slli	a5,a5,0x30
    8000580e:	93c1                	srli	a5,a5,0x30
    80005810:	4705                	li	a4,1
    80005812:	00f76d63          	bltu	a4,a5,8000582c <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005816:	8556                	mv	a0,s5
    80005818:	60a6                	ld	ra,72(sp)
    8000581a:	6406                	ld	s0,64(sp)
    8000581c:	74e2                	ld	s1,56(sp)
    8000581e:	7942                	ld	s2,48(sp)
    80005820:	79a2                	ld	s3,40(sp)
    80005822:	7a02                	ld	s4,32(sp)
    80005824:	6ae2                	ld	s5,24(sp)
    80005826:	6b42                	ld	s6,16(sp)
    80005828:	6161                	addi	sp,sp,80
    8000582a:	8082                	ret
    iunlockput(ip);
    8000582c:	8556                	mv	a0,s5
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	86a080e7          	jalr	-1942(ra) # 80004098 <iunlockput>
    return 0;
    80005836:	4a81                	li	s5,0
    80005838:	bff9                	j	80005816 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000583a:	85da                	mv	a1,s6
    8000583c:	4088                	lw	a0,0(s1)
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	45c080e7          	jalr	1116(ra) # 80003c9a <ialloc>
    80005846:	8a2a                	mv	s4,a0
    80005848:	c539                	beqz	a0,80005896 <create+0xf6>
  ilock(ip);
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	5ec080e7          	jalr	1516(ra) # 80003e36 <ilock>
  ip->major = major;
    80005852:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005856:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000585a:	4905                	li	s2,1
    8000585c:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005860:	8552                	mv	a0,s4
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	50a080e7          	jalr	1290(ra) # 80003d6c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000586a:	000b059b          	sext.w	a1,s6
    8000586e:	03258b63          	beq	a1,s2,800058a4 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005872:	004a2603          	lw	a2,4(s4)
    80005876:	fb040593          	addi	a1,s0,-80
    8000587a:	8526                	mv	a0,s1
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	cae080e7          	jalr	-850(ra) # 8000452a <dirlink>
    80005884:	06054f63          	bltz	a0,80005902 <create+0x162>
  iunlockput(dp);
    80005888:	8526                	mv	a0,s1
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	80e080e7          	jalr	-2034(ra) # 80004098 <iunlockput>
  return ip;
    80005892:	8ad2                	mv	s5,s4
    80005894:	b749                	j	80005816 <create+0x76>
    iunlockput(dp);
    80005896:	8526                	mv	a0,s1
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	800080e7          	jalr	-2048(ra) # 80004098 <iunlockput>
    return 0;
    800058a0:	8ad2                	mv	s5,s4
    800058a2:	bf95                	j	80005816 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800058a4:	004a2603          	lw	a2,4(s4)
    800058a8:	00003597          	auipc	a1,0x3
    800058ac:	e6058593          	addi	a1,a1,-416 # 80008708 <syscalls+0x2b8>
    800058b0:	8552                	mv	a0,s4
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	c78080e7          	jalr	-904(ra) # 8000452a <dirlink>
    800058ba:	04054463          	bltz	a0,80005902 <create+0x162>
    800058be:	40d0                	lw	a2,4(s1)
    800058c0:	00003597          	auipc	a1,0x3
    800058c4:	e5058593          	addi	a1,a1,-432 # 80008710 <syscalls+0x2c0>
    800058c8:	8552                	mv	a0,s4
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	c60080e7          	jalr	-928(ra) # 8000452a <dirlink>
    800058d2:	02054863          	bltz	a0,80005902 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800058d6:	004a2603          	lw	a2,4(s4)
    800058da:	fb040593          	addi	a1,s0,-80
    800058de:	8526                	mv	a0,s1
    800058e0:	fffff097          	auipc	ra,0xfffff
    800058e4:	c4a080e7          	jalr	-950(ra) # 8000452a <dirlink>
    800058e8:	00054d63          	bltz	a0,80005902 <create+0x162>
    dp->nlink++;  // for ".."
    800058ec:	04a4d783          	lhu	a5,74(s1)
    800058f0:	2785                	addiw	a5,a5,1
    800058f2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058f6:	8526                	mv	a0,s1
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	474080e7          	jalr	1140(ra) # 80003d6c <iupdate>
    80005900:	b761                	j	80005888 <create+0xe8>
  ip->nlink = 0;
    80005902:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005906:	8552                	mv	a0,s4
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	464080e7          	jalr	1124(ra) # 80003d6c <iupdate>
  iunlockput(ip);
    80005910:	8552                	mv	a0,s4
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	786080e7          	jalr	1926(ra) # 80004098 <iunlockput>
  iunlockput(dp);
    8000591a:	8526                	mv	a0,s1
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	77c080e7          	jalr	1916(ra) # 80004098 <iunlockput>
  return 0;
    80005924:	bdcd                	j	80005816 <create+0x76>
    return 0;
    80005926:	8aaa                	mv	s5,a0
    80005928:	b5fd                	j	80005816 <create+0x76>

000000008000592a <sys_dup>:
{
    8000592a:	7179                	addi	sp,sp,-48
    8000592c:	f406                	sd	ra,40(sp)
    8000592e:	f022                	sd	s0,32(sp)
    80005930:	ec26                	sd	s1,24(sp)
    80005932:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005934:	fd840613          	addi	a2,s0,-40
    80005938:	4581                	li	a1,0
    8000593a:	4501                	li	a0,0
    8000593c:	00000097          	auipc	ra,0x0
    80005940:	dc2080e7          	jalr	-574(ra) # 800056fe <argfd>
    return -1;
    80005944:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005946:	02054363          	bltz	a0,8000596c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000594a:	fd843503          	ld	a0,-40(s0)
    8000594e:	00000097          	auipc	ra,0x0
    80005952:	e10080e7          	jalr	-496(ra) # 8000575e <fdalloc>
    80005956:	84aa                	mv	s1,a0
    return -1;
    80005958:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000595a:	00054963          	bltz	a0,8000596c <sys_dup+0x42>
  filedup(f);
    8000595e:	fd843503          	ld	a0,-40(s0)
    80005962:	fffff097          	auipc	ra,0xfffff
    80005966:	310080e7          	jalr	784(ra) # 80004c72 <filedup>
  return fd;
    8000596a:	87a6                	mv	a5,s1
}
    8000596c:	853e                	mv	a0,a5
    8000596e:	70a2                	ld	ra,40(sp)
    80005970:	7402                	ld	s0,32(sp)
    80005972:	64e2                	ld	s1,24(sp)
    80005974:	6145                	addi	sp,sp,48
    80005976:	8082                	ret

0000000080005978 <sys_getreadcount>:
{
    80005978:	1141                	addi	sp,sp,-16
    8000597a:	e422                	sd	s0,8(sp)
    8000597c:	0800                	addi	s0,sp,16
}
    8000597e:	00003517          	auipc	a0,0x3
    80005982:	f6652503          	lw	a0,-154(a0) # 800088e4 <readCount>
    80005986:	6422                	ld	s0,8(sp)
    80005988:	0141                	addi	sp,sp,16
    8000598a:	8082                	ret

000000008000598c <sys_read>:
{
    8000598c:	7179                	addi	sp,sp,-48
    8000598e:	f406                	sd	ra,40(sp)
    80005990:	f022                	sd	s0,32(sp)
    80005992:	1800                	addi	s0,sp,48
  readCount++;
    80005994:	00003717          	auipc	a4,0x3
    80005998:	f5070713          	addi	a4,a4,-176 # 800088e4 <readCount>
    8000599c:	431c                	lw	a5,0(a4)
    8000599e:	2785                	addiw	a5,a5,1
    800059a0:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    800059a2:	fd840593          	addi	a1,s0,-40
    800059a6:	4505                	li	a0,1
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	8a6080e7          	jalr	-1882(ra) # 8000324e <argaddr>
  argint(2, &n);
    800059b0:	fe440593          	addi	a1,s0,-28
    800059b4:	4509                	li	a0,2
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	878080e7          	jalr	-1928(ra) # 8000322e <argint>
  if(argfd(0, 0, &f) < 0)
    800059be:	fe840613          	addi	a2,s0,-24
    800059c2:	4581                	li	a1,0
    800059c4:	4501                	li	a0,0
    800059c6:	00000097          	auipc	ra,0x0
    800059ca:	d38080e7          	jalr	-712(ra) # 800056fe <argfd>
    800059ce:	87aa                	mv	a5,a0
    return -1;
    800059d0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800059d2:	0007cc63          	bltz	a5,800059ea <sys_read+0x5e>
  return fileread(f, p, n);
    800059d6:	fe442603          	lw	a2,-28(s0)
    800059da:	fd843583          	ld	a1,-40(s0)
    800059de:	fe843503          	ld	a0,-24(s0)
    800059e2:	fffff097          	auipc	ra,0xfffff
    800059e6:	41c080e7          	jalr	1052(ra) # 80004dfe <fileread>
}
    800059ea:	70a2                	ld	ra,40(sp)
    800059ec:	7402                	ld	s0,32(sp)
    800059ee:	6145                	addi	sp,sp,48
    800059f0:	8082                	ret

00000000800059f2 <sys_set_priority>:
{
    800059f2:	7139                	addi	sp,sp,-64
    800059f4:	fc06                	sd	ra,56(sp)
    800059f6:	f822                	sd	s0,48(sp)
    800059f8:	f426                	sd	s1,40(sp)
    800059fa:	f04a                	sd	s2,32(sp)
    800059fc:	ec4e                	sd	s3,24(sp)
    800059fe:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80005a00:	ffffc097          	auipc	ra,0xffffc
    80005a04:	0cc080e7          	jalr	204(ra) # 80001acc <myproc>
  argint(0, &pid);
    80005a08:	fcc40593          	addi	a1,s0,-52
    80005a0c:	4501                	li	a0,0
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	820080e7          	jalr	-2016(ra) # 8000322e <argint>
  argaddr(1, &new_priority);
    80005a16:	fc040593          	addi	a1,s0,-64
    80005a1a:	4505                	li	a0,1
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	832080e7          	jalr	-1998(ra) # 8000324e <argaddr>
  for (p = proc; p < &proc[NPROC]; p++)
    80005a24:	0022b497          	auipc	s1,0x22b
    80005a28:	57448493          	addi	s1,s1,1396 # 80230f98 <proc>
    80005a2c:	00232917          	auipc	s2,0x232
    80005a30:	b6c90913          	addi	s2,s2,-1172 # 80237598 <tickslock>
      acquire(&p->lock);
    80005a34:	8526                	mv	a0,s1
    80005a36:	ffffb097          	auipc	ra,0xffffb
    80005a3a:	206080e7          	jalr	518(ra) # 80000c3c <acquire>
      if(p->pid==pid)
    80005a3e:	5898                	lw	a4,48(s1)
    80005a40:	fcc42783          	lw	a5,-52(s0)
    80005a44:	00f70f63          	beq	a4,a5,80005a62 <sys_set_priority+0x70>
      release(&p->lock);
    80005a48:	8526                	mv	a0,s1
    80005a4a:	ffffb097          	auipc	ra,0xffffb
    80005a4e:	2a6080e7          	jalr	678(ra) # 80000cf0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80005a52:	19848493          	addi	s1,s1,408
    80005a56:	fd249fe3          	bne	s1,s2,80005a34 <sys_set_priority+0x42>
  int old_dp=0;
    80005a5a:	4981                	li	s3,0
  int old_priority=50;
    80005a5c:	03200913          	li	s2,50
    80005a60:	a815                	j	80005a94 <sys_set_priority+0xa2>
        old_priority=p->sp;
    80005a62:	1744a903          	lw	s2,372(s1)
        p->sp=new_priority;
    80005a66:	fc043783          	ld	a5,-64(s0)
    80005a6a:	16f4aa23          	sw	a5,372(s1)
        p->rbi=25;
    80005a6e:	4765                	li	a4,25
    80005a70:	16e4ae23          	sw	a4,380(s1)
        old_dp=p->dp;
    80005a74:	1784a983          	lw	s3,376(s1)
        int new_dp= new_priority + 25 > 100 ? 100 : new_priority + 25;
    80005a78:	07e5                	addi	a5,a5,25
    80005a7a:	06400713          	li	a4,100
    80005a7e:	00f77463          	bgeu	a4,a5,80005a86 <sys_set_priority+0x94>
    80005a82:	06400793          	li	a5,100
    80005a86:	16f4ac23          	sw	a5,376(s1)
        release(&p->lock);
    80005a8a:	8526                	mv	a0,s1
    80005a8c:	ffffb097          	auipc	ra,0xffffb
    80005a90:	264080e7          	jalr	612(ra) # 80000cf0 <release>
    int new_dp= new_priority + 25 > 100 ? 100 : new_priority + 25;
    80005a94:	fc043783          	ld	a5,-64(s0)
    80005a98:	07e5                	addi	a5,a5,25
    80005a9a:	06400713          	li	a4,100
    80005a9e:	00f77463          	bgeu	a4,a5,80005aa6 <sys_set_priority+0xb4>
    80005aa2:	06400793          	li	a5,100
    if(new_dp > old_dp)
    80005aa6:	2781                	sext.w	a5,a5
  return old_priority;
    80005aa8:	854a                	mv	a0,s2
    if(new_dp > old_dp)
    80005aaa:	00f9c963          	blt	s3,a5,80005abc <sys_set_priority+0xca>
}
    80005aae:	70e2                	ld	ra,56(sp)
    80005ab0:	7442                	ld	s0,48(sp)
    80005ab2:	74a2                	ld	s1,40(sp)
    80005ab4:	7902                	ld	s2,32(sp)
    80005ab6:	69e2                	ld	s3,24(sp)
    80005ab8:	6121                	addi	sp,sp,64
    80005aba:	8082                	ret
         yield();
    80005abc:	ffffd097          	auipc	ra,0xffffd
    80005ac0:	9fa080e7          	jalr	-1542(ra) # 800024b6 <yield>
         return old_priority;
    80005ac4:	854a                	mv	a0,s2
    80005ac6:	b7e5                	j	80005aae <sys_set_priority+0xbc>

0000000080005ac8 <sys_write>:
{
    80005ac8:	7179                	addi	sp,sp,-48
    80005aca:	f406                	sd	ra,40(sp)
    80005acc:	f022                	sd	s0,32(sp)
    80005ace:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005ad0:	fd840593          	addi	a1,s0,-40
    80005ad4:	4505                	li	a0,1
    80005ad6:	ffffd097          	auipc	ra,0xffffd
    80005ada:	778080e7          	jalr	1912(ra) # 8000324e <argaddr>
  argint(2, &n);
    80005ade:	fe440593          	addi	a1,s0,-28
    80005ae2:	4509                	li	a0,2
    80005ae4:	ffffd097          	auipc	ra,0xffffd
    80005ae8:	74a080e7          	jalr	1866(ra) # 8000322e <argint>
  if(argfd(0, 0, &f) < 0)
    80005aec:	fe840613          	addi	a2,s0,-24
    80005af0:	4581                	li	a1,0
    80005af2:	4501                	li	a0,0
    80005af4:	00000097          	auipc	ra,0x0
    80005af8:	c0a080e7          	jalr	-1014(ra) # 800056fe <argfd>
    80005afc:	87aa                	mv	a5,a0
    return -1;
    80005afe:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b00:	0007cc63          	bltz	a5,80005b18 <sys_write+0x50>
  return filewrite(f, p, n);
    80005b04:	fe442603          	lw	a2,-28(s0)
    80005b08:	fd843583          	ld	a1,-40(s0)
    80005b0c:	fe843503          	ld	a0,-24(s0)
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	3b0080e7          	jalr	944(ra) # 80004ec0 <filewrite>
}
    80005b18:	70a2                	ld	ra,40(sp)
    80005b1a:	7402                	ld	s0,32(sp)
    80005b1c:	6145                	addi	sp,sp,48
    80005b1e:	8082                	ret

0000000080005b20 <sys_close>:
{
    80005b20:	1101                	addi	sp,sp,-32
    80005b22:	ec06                	sd	ra,24(sp)
    80005b24:	e822                	sd	s0,16(sp)
    80005b26:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005b28:	fe040613          	addi	a2,s0,-32
    80005b2c:	fec40593          	addi	a1,s0,-20
    80005b30:	4501                	li	a0,0
    80005b32:	00000097          	auipc	ra,0x0
    80005b36:	bcc080e7          	jalr	-1076(ra) # 800056fe <argfd>
    return -1;
    80005b3a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005b3c:	02054463          	bltz	a0,80005b64 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005b40:	ffffc097          	auipc	ra,0xffffc
    80005b44:	f8c080e7          	jalr	-116(ra) # 80001acc <myproc>
    80005b48:	fec42783          	lw	a5,-20(s0)
    80005b4c:	07e9                	addi	a5,a5,26
    80005b4e:	078e                	slli	a5,a5,0x3
    80005b50:	97aa                	add	a5,a5,a0
    80005b52:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005b56:	fe043503          	ld	a0,-32(s0)
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	16a080e7          	jalr	362(ra) # 80004cc4 <fileclose>
  return 0;
    80005b62:	4781                	li	a5,0
}
    80005b64:	853e                	mv	a0,a5
    80005b66:	60e2                	ld	ra,24(sp)
    80005b68:	6442                	ld	s0,16(sp)
    80005b6a:	6105                	addi	sp,sp,32
    80005b6c:	8082                	ret

0000000080005b6e <sys_fstat>:
{
    80005b6e:	1101                	addi	sp,sp,-32
    80005b70:	ec06                	sd	ra,24(sp)
    80005b72:	e822                	sd	s0,16(sp)
    80005b74:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005b76:	fe040593          	addi	a1,s0,-32
    80005b7a:	4505                	li	a0,1
    80005b7c:	ffffd097          	auipc	ra,0xffffd
    80005b80:	6d2080e7          	jalr	1746(ra) # 8000324e <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005b84:	fe840613          	addi	a2,s0,-24
    80005b88:	4581                	li	a1,0
    80005b8a:	4501                	li	a0,0
    80005b8c:	00000097          	auipc	ra,0x0
    80005b90:	b72080e7          	jalr	-1166(ra) # 800056fe <argfd>
    80005b94:	87aa                	mv	a5,a0
    return -1;
    80005b96:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b98:	0007ca63          	bltz	a5,80005bac <sys_fstat+0x3e>
  return filestat(f, st);
    80005b9c:	fe043583          	ld	a1,-32(s0)
    80005ba0:	fe843503          	ld	a0,-24(s0)
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	1e8080e7          	jalr	488(ra) # 80004d8c <filestat>
}
    80005bac:	60e2                	ld	ra,24(sp)
    80005bae:	6442                	ld	s0,16(sp)
    80005bb0:	6105                	addi	sp,sp,32
    80005bb2:	8082                	ret

0000000080005bb4 <sys_link>:
{
    80005bb4:	7169                	addi	sp,sp,-304
    80005bb6:	f606                	sd	ra,296(sp)
    80005bb8:	f222                	sd	s0,288(sp)
    80005bba:	ee26                	sd	s1,280(sp)
    80005bbc:	ea4a                	sd	s2,272(sp)
    80005bbe:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bc0:	08000613          	li	a2,128
    80005bc4:	ed040593          	addi	a1,s0,-304
    80005bc8:	4501                	li	a0,0
    80005bca:	ffffd097          	auipc	ra,0xffffd
    80005bce:	6a4080e7          	jalr	1700(ra) # 8000326e <argstr>
    return -1;
    80005bd2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bd4:	10054e63          	bltz	a0,80005cf0 <sys_link+0x13c>
    80005bd8:	08000613          	li	a2,128
    80005bdc:	f5040593          	addi	a1,s0,-176
    80005be0:	4505                	li	a0,1
    80005be2:	ffffd097          	auipc	ra,0xffffd
    80005be6:	68c080e7          	jalr	1676(ra) # 8000326e <argstr>
    return -1;
    80005bea:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bec:	10054263          	bltz	a0,80005cf0 <sys_link+0x13c>
  begin_op();
    80005bf0:	fffff097          	auipc	ra,0xfffff
    80005bf4:	c08080e7          	jalr	-1016(ra) # 800047f8 <begin_op>
  if((ip = namei(old)) == 0){
    80005bf8:	ed040513          	addi	a0,s0,-304
    80005bfc:	fffff097          	auipc	ra,0xfffff
    80005c00:	9e0080e7          	jalr	-1568(ra) # 800045dc <namei>
    80005c04:	84aa                	mv	s1,a0
    80005c06:	c551                	beqz	a0,80005c92 <sys_link+0xde>
  ilock(ip);
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	22e080e7          	jalr	558(ra) # 80003e36 <ilock>
  if(ip->type == T_DIR){
    80005c10:	04449703          	lh	a4,68(s1)
    80005c14:	4785                	li	a5,1
    80005c16:	08f70463          	beq	a4,a5,80005c9e <sys_link+0xea>
  ip->nlink++;
    80005c1a:	04a4d783          	lhu	a5,74(s1)
    80005c1e:	2785                	addiw	a5,a5,1
    80005c20:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c24:	8526                	mv	a0,s1
    80005c26:	ffffe097          	auipc	ra,0xffffe
    80005c2a:	146080e7          	jalr	326(ra) # 80003d6c <iupdate>
  iunlock(ip);
    80005c2e:	8526                	mv	a0,s1
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	2c8080e7          	jalr	712(ra) # 80003ef8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005c38:	fd040593          	addi	a1,s0,-48
    80005c3c:	f5040513          	addi	a0,s0,-176
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	9ba080e7          	jalr	-1606(ra) # 800045fa <nameiparent>
    80005c48:	892a                	mv	s2,a0
    80005c4a:	c935                	beqz	a0,80005cbe <sys_link+0x10a>
  ilock(dp);
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	1ea080e7          	jalr	490(ra) # 80003e36 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005c54:	00092703          	lw	a4,0(s2)
    80005c58:	409c                	lw	a5,0(s1)
    80005c5a:	04f71d63          	bne	a4,a5,80005cb4 <sys_link+0x100>
    80005c5e:	40d0                	lw	a2,4(s1)
    80005c60:	fd040593          	addi	a1,s0,-48
    80005c64:	854a                	mv	a0,s2
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	8c4080e7          	jalr	-1852(ra) # 8000452a <dirlink>
    80005c6e:	04054363          	bltz	a0,80005cb4 <sys_link+0x100>
  iunlockput(dp);
    80005c72:	854a                	mv	a0,s2
    80005c74:	ffffe097          	auipc	ra,0xffffe
    80005c78:	424080e7          	jalr	1060(ra) # 80004098 <iunlockput>
  iput(ip);
    80005c7c:	8526                	mv	a0,s1
    80005c7e:	ffffe097          	auipc	ra,0xffffe
    80005c82:	372080e7          	jalr	882(ra) # 80003ff0 <iput>
  end_op();
    80005c86:	fffff097          	auipc	ra,0xfffff
    80005c8a:	bf2080e7          	jalr	-1038(ra) # 80004878 <end_op>
  return 0;
    80005c8e:	4781                	li	a5,0
    80005c90:	a085                	j	80005cf0 <sys_link+0x13c>
    end_op();
    80005c92:	fffff097          	auipc	ra,0xfffff
    80005c96:	be6080e7          	jalr	-1050(ra) # 80004878 <end_op>
    return -1;
    80005c9a:	57fd                	li	a5,-1
    80005c9c:	a891                	j	80005cf0 <sys_link+0x13c>
    iunlockput(ip);
    80005c9e:	8526                	mv	a0,s1
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	3f8080e7          	jalr	1016(ra) # 80004098 <iunlockput>
    end_op();
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	bd0080e7          	jalr	-1072(ra) # 80004878 <end_op>
    return -1;
    80005cb0:	57fd                	li	a5,-1
    80005cb2:	a83d                	j	80005cf0 <sys_link+0x13c>
    iunlockput(dp);
    80005cb4:	854a                	mv	a0,s2
    80005cb6:	ffffe097          	auipc	ra,0xffffe
    80005cba:	3e2080e7          	jalr	994(ra) # 80004098 <iunlockput>
  ilock(ip);
    80005cbe:	8526                	mv	a0,s1
    80005cc0:	ffffe097          	auipc	ra,0xffffe
    80005cc4:	176080e7          	jalr	374(ra) # 80003e36 <ilock>
  ip->nlink--;
    80005cc8:	04a4d783          	lhu	a5,74(s1)
    80005ccc:	37fd                	addiw	a5,a5,-1
    80005cce:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005cd2:	8526                	mv	a0,s1
    80005cd4:	ffffe097          	auipc	ra,0xffffe
    80005cd8:	098080e7          	jalr	152(ra) # 80003d6c <iupdate>
  iunlockput(ip);
    80005cdc:	8526                	mv	a0,s1
    80005cde:	ffffe097          	auipc	ra,0xffffe
    80005ce2:	3ba080e7          	jalr	954(ra) # 80004098 <iunlockput>
  end_op();
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	b92080e7          	jalr	-1134(ra) # 80004878 <end_op>
  return -1;
    80005cee:	57fd                	li	a5,-1
}
    80005cf0:	853e                	mv	a0,a5
    80005cf2:	70b2                	ld	ra,296(sp)
    80005cf4:	7412                	ld	s0,288(sp)
    80005cf6:	64f2                	ld	s1,280(sp)
    80005cf8:	6952                	ld	s2,272(sp)
    80005cfa:	6155                	addi	sp,sp,304
    80005cfc:	8082                	ret

0000000080005cfe <sys_unlink>:
{
    80005cfe:	7151                	addi	sp,sp,-240
    80005d00:	f586                	sd	ra,232(sp)
    80005d02:	f1a2                	sd	s0,224(sp)
    80005d04:	eda6                	sd	s1,216(sp)
    80005d06:	e9ca                	sd	s2,208(sp)
    80005d08:	e5ce                	sd	s3,200(sp)
    80005d0a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005d0c:	08000613          	li	a2,128
    80005d10:	f3040593          	addi	a1,s0,-208
    80005d14:	4501                	li	a0,0
    80005d16:	ffffd097          	auipc	ra,0xffffd
    80005d1a:	558080e7          	jalr	1368(ra) # 8000326e <argstr>
    80005d1e:	18054163          	bltz	a0,80005ea0 <sys_unlink+0x1a2>
  begin_op();
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	ad6080e7          	jalr	-1322(ra) # 800047f8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005d2a:	fb040593          	addi	a1,s0,-80
    80005d2e:	f3040513          	addi	a0,s0,-208
    80005d32:	fffff097          	auipc	ra,0xfffff
    80005d36:	8c8080e7          	jalr	-1848(ra) # 800045fa <nameiparent>
    80005d3a:	84aa                	mv	s1,a0
    80005d3c:	c979                	beqz	a0,80005e12 <sys_unlink+0x114>
  ilock(dp);
    80005d3e:	ffffe097          	auipc	ra,0xffffe
    80005d42:	0f8080e7          	jalr	248(ra) # 80003e36 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005d46:	00003597          	auipc	a1,0x3
    80005d4a:	9c258593          	addi	a1,a1,-1598 # 80008708 <syscalls+0x2b8>
    80005d4e:	fb040513          	addi	a0,s0,-80
    80005d52:	ffffe097          	auipc	ra,0xffffe
    80005d56:	5ae080e7          	jalr	1454(ra) # 80004300 <namecmp>
    80005d5a:	14050a63          	beqz	a0,80005eae <sys_unlink+0x1b0>
    80005d5e:	00003597          	auipc	a1,0x3
    80005d62:	9b258593          	addi	a1,a1,-1614 # 80008710 <syscalls+0x2c0>
    80005d66:	fb040513          	addi	a0,s0,-80
    80005d6a:	ffffe097          	auipc	ra,0xffffe
    80005d6e:	596080e7          	jalr	1430(ra) # 80004300 <namecmp>
    80005d72:	12050e63          	beqz	a0,80005eae <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005d76:	f2c40613          	addi	a2,s0,-212
    80005d7a:	fb040593          	addi	a1,s0,-80
    80005d7e:	8526                	mv	a0,s1
    80005d80:	ffffe097          	auipc	ra,0xffffe
    80005d84:	59a080e7          	jalr	1434(ra) # 8000431a <dirlookup>
    80005d88:	892a                	mv	s2,a0
    80005d8a:	12050263          	beqz	a0,80005eae <sys_unlink+0x1b0>
  ilock(ip);
    80005d8e:	ffffe097          	auipc	ra,0xffffe
    80005d92:	0a8080e7          	jalr	168(ra) # 80003e36 <ilock>
  if(ip->nlink < 1)
    80005d96:	04a91783          	lh	a5,74(s2)
    80005d9a:	08f05263          	blez	a5,80005e1e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005d9e:	04491703          	lh	a4,68(s2)
    80005da2:	4785                	li	a5,1
    80005da4:	08f70563          	beq	a4,a5,80005e2e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005da8:	4641                	li	a2,16
    80005daa:	4581                	li	a1,0
    80005dac:	fc040513          	addi	a0,s0,-64
    80005db0:	ffffb097          	auipc	ra,0xffffb
    80005db4:	f88080e7          	jalr	-120(ra) # 80000d38 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005db8:	4741                	li	a4,16
    80005dba:	f2c42683          	lw	a3,-212(s0)
    80005dbe:	fc040613          	addi	a2,s0,-64
    80005dc2:	4581                	li	a1,0
    80005dc4:	8526                	mv	a0,s1
    80005dc6:	ffffe097          	auipc	ra,0xffffe
    80005dca:	41c080e7          	jalr	1052(ra) # 800041e2 <writei>
    80005dce:	47c1                	li	a5,16
    80005dd0:	0af51563          	bne	a0,a5,80005e7a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005dd4:	04491703          	lh	a4,68(s2)
    80005dd8:	4785                	li	a5,1
    80005dda:	0af70863          	beq	a4,a5,80005e8a <sys_unlink+0x18c>
  iunlockput(dp);
    80005dde:	8526                	mv	a0,s1
    80005de0:	ffffe097          	auipc	ra,0xffffe
    80005de4:	2b8080e7          	jalr	696(ra) # 80004098 <iunlockput>
  ip->nlink--;
    80005de8:	04a95783          	lhu	a5,74(s2)
    80005dec:	37fd                	addiw	a5,a5,-1
    80005dee:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005df2:	854a                	mv	a0,s2
    80005df4:	ffffe097          	auipc	ra,0xffffe
    80005df8:	f78080e7          	jalr	-136(ra) # 80003d6c <iupdate>
  iunlockput(ip);
    80005dfc:	854a                	mv	a0,s2
    80005dfe:	ffffe097          	auipc	ra,0xffffe
    80005e02:	29a080e7          	jalr	666(ra) # 80004098 <iunlockput>
  end_op();
    80005e06:	fffff097          	auipc	ra,0xfffff
    80005e0a:	a72080e7          	jalr	-1422(ra) # 80004878 <end_op>
  return 0;
    80005e0e:	4501                	li	a0,0
    80005e10:	a84d                	j	80005ec2 <sys_unlink+0x1c4>
    end_op();
    80005e12:	fffff097          	auipc	ra,0xfffff
    80005e16:	a66080e7          	jalr	-1434(ra) # 80004878 <end_op>
    return -1;
    80005e1a:	557d                	li	a0,-1
    80005e1c:	a05d                	j	80005ec2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005e1e:	00003517          	auipc	a0,0x3
    80005e22:	8fa50513          	addi	a0,a0,-1798 # 80008718 <syscalls+0x2c8>
    80005e26:	ffffa097          	auipc	ra,0xffffa
    80005e2a:	718080e7          	jalr	1816(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e2e:	04c92703          	lw	a4,76(s2)
    80005e32:	02000793          	li	a5,32
    80005e36:	f6e7f9e3          	bgeu	a5,a4,80005da8 <sys_unlink+0xaa>
    80005e3a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e3e:	4741                	li	a4,16
    80005e40:	86ce                	mv	a3,s3
    80005e42:	f1840613          	addi	a2,s0,-232
    80005e46:	4581                	li	a1,0
    80005e48:	854a                	mv	a0,s2
    80005e4a:	ffffe097          	auipc	ra,0xffffe
    80005e4e:	2a0080e7          	jalr	672(ra) # 800040ea <readi>
    80005e52:	47c1                	li	a5,16
    80005e54:	00f51b63          	bne	a0,a5,80005e6a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005e58:	f1845783          	lhu	a5,-232(s0)
    80005e5c:	e7a1                	bnez	a5,80005ea4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e5e:	29c1                	addiw	s3,s3,16
    80005e60:	04c92783          	lw	a5,76(s2)
    80005e64:	fcf9ede3          	bltu	s3,a5,80005e3e <sys_unlink+0x140>
    80005e68:	b781                	j	80005da8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005e6a:	00003517          	auipc	a0,0x3
    80005e6e:	8c650513          	addi	a0,a0,-1850 # 80008730 <syscalls+0x2e0>
    80005e72:	ffffa097          	auipc	ra,0xffffa
    80005e76:	6cc080e7          	jalr	1740(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005e7a:	00003517          	auipc	a0,0x3
    80005e7e:	8ce50513          	addi	a0,a0,-1842 # 80008748 <syscalls+0x2f8>
    80005e82:	ffffa097          	auipc	ra,0xffffa
    80005e86:	6bc080e7          	jalr	1724(ra) # 8000053e <panic>
    dp->nlink--;
    80005e8a:	04a4d783          	lhu	a5,74(s1)
    80005e8e:	37fd                	addiw	a5,a5,-1
    80005e90:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005e94:	8526                	mv	a0,s1
    80005e96:	ffffe097          	auipc	ra,0xffffe
    80005e9a:	ed6080e7          	jalr	-298(ra) # 80003d6c <iupdate>
    80005e9e:	b781                	j	80005dde <sys_unlink+0xe0>
    return -1;
    80005ea0:	557d                	li	a0,-1
    80005ea2:	a005                	j	80005ec2 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005ea4:	854a                	mv	a0,s2
    80005ea6:	ffffe097          	auipc	ra,0xffffe
    80005eaa:	1f2080e7          	jalr	498(ra) # 80004098 <iunlockput>
  iunlockput(dp);
    80005eae:	8526                	mv	a0,s1
    80005eb0:	ffffe097          	auipc	ra,0xffffe
    80005eb4:	1e8080e7          	jalr	488(ra) # 80004098 <iunlockput>
  end_op();
    80005eb8:	fffff097          	auipc	ra,0xfffff
    80005ebc:	9c0080e7          	jalr	-1600(ra) # 80004878 <end_op>
  return -1;
    80005ec0:	557d                	li	a0,-1
}
    80005ec2:	70ae                	ld	ra,232(sp)
    80005ec4:	740e                	ld	s0,224(sp)
    80005ec6:	64ee                	ld	s1,216(sp)
    80005ec8:	694e                	ld	s2,208(sp)
    80005eca:	69ae                	ld	s3,200(sp)
    80005ecc:	616d                	addi	sp,sp,240
    80005ece:	8082                	ret

0000000080005ed0 <sys_open>:

uint64
sys_open(void)
{
    80005ed0:	7131                	addi	sp,sp,-192
    80005ed2:	fd06                	sd	ra,184(sp)
    80005ed4:	f922                	sd	s0,176(sp)
    80005ed6:	f526                	sd	s1,168(sp)
    80005ed8:	f14a                	sd	s2,160(sp)
    80005eda:	ed4e                	sd	s3,152(sp)
    80005edc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005ede:	f4c40593          	addi	a1,s0,-180
    80005ee2:	4505                	li	a0,1
    80005ee4:	ffffd097          	auipc	ra,0xffffd
    80005ee8:	34a080e7          	jalr	842(ra) # 8000322e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005eec:	08000613          	li	a2,128
    80005ef0:	f5040593          	addi	a1,s0,-176
    80005ef4:	4501                	li	a0,0
    80005ef6:	ffffd097          	auipc	ra,0xffffd
    80005efa:	378080e7          	jalr	888(ra) # 8000326e <argstr>
    80005efe:	87aa                	mv	a5,a0
    return -1;
    80005f00:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005f02:	0a07c963          	bltz	a5,80005fb4 <sys_open+0xe4>

  begin_op();
    80005f06:	fffff097          	auipc	ra,0xfffff
    80005f0a:	8f2080e7          	jalr	-1806(ra) # 800047f8 <begin_op>

  if(omode & O_CREATE){
    80005f0e:	f4c42783          	lw	a5,-180(s0)
    80005f12:	2007f793          	andi	a5,a5,512
    80005f16:	cfc5                	beqz	a5,80005fce <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005f18:	4681                	li	a3,0
    80005f1a:	4601                	li	a2,0
    80005f1c:	4589                	li	a1,2
    80005f1e:	f5040513          	addi	a0,s0,-176
    80005f22:	00000097          	auipc	ra,0x0
    80005f26:	87e080e7          	jalr	-1922(ra) # 800057a0 <create>
    80005f2a:	84aa                	mv	s1,a0
    if(ip == 0){
    80005f2c:	c959                	beqz	a0,80005fc2 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005f2e:	04449703          	lh	a4,68(s1)
    80005f32:	478d                	li	a5,3
    80005f34:	00f71763          	bne	a4,a5,80005f42 <sys_open+0x72>
    80005f38:	0464d703          	lhu	a4,70(s1)
    80005f3c:	47a5                	li	a5,9
    80005f3e:	0ce7ed63          	bltu	a5,a4,80006018 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005f42:	fffff097          	auipc	ra,0xfffff
    80005f46:	cc6080e7          	jalr	-826(ra) # 80004c08 <filealloc>
    80005f4a:	89aa                	mv	s3,a0
    80005f4c:	10050363          	beqz	a0,80006052 <sys_open+0x182>
    80005f50:	00000097          	auipc	ra,0x0
    80005f54:	80e080e7          	jalr	-2034(ra) # 8000575e <fdalloc>
    80005f58:	892a                	mv	s2,a0
    80005f5a:	0e054763          	bltz	a0,80006048 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005f5e:	04449703          	lh	a4,68(s1)
    80005f62:	478d                	li	a5,3
    80005f64:	0cf70563          	beq	a4,a5,8000602e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005f68:	4789                	li	a5,2
    80005f6a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005f6e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005f72:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005f76:	f4c42783          	lw	a5,-180(s0)
    80005f7a:	0017c713          	xori	a4,a5,1
    80005f7e:	8b05                	andi	a4,a4,1
    80005f80:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005f84:	0037f713          	andi	a4,a5,3
    80005f88:	00e03733          	snez	a4,a4
    80005f8c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005f90:	4007f793          	andi	a5,a5,1024
    80005f94:	c791                	beqz	a5,80005fa0 <sys_open+0xd0>
    80005f96:	04449703          	lh	a4,68(s1)
    80005f9a:	4789                	li	a5,2
    80005f9c:	0af70063          	beq	a4,a5,8000603c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005fa0:	8526                	mv	a0,s1
    80005fa2:	ffffe097          	auipc	ra,0xffffe
    80005fa6:	f56080e7          	jalr	-170(ra) # 80003ef8 <iunlock>
  end_op();
    80005faa:	fffff097          	auipc	ra,0xfffff
    80005fae:	8ce080e7          	jalr	-1842(ra) # 80004878 <end_op>

  return fd;
    80005fb2:	854a                	mv	a0,s2
}
    80005fb4:	70ea                	ld	ra,184(sp)
    80005fb6:	744a                	ld	s0,176(sp)
    80005fb8:	74aa                	ld	s1,168(sp)
    80005fba:	790a                	ld	s2,160(sp)
    80005fbc:	69ea                	ld	s3,152(sp)
    80005fbe:	6129                	addi	sp,sp,192
    80005fc0:	8082                	ret
      end_op();
    80005fc2:	fffff097          	auipc	ra,0xfffff
    80005fc6:	8b6080e7          	jalr	-1866(ra) # 80004878 <end_op>
      return -1;
    80005fca:	557d                	li	a0,-1
    80005fcc:	b7e5                	j	80005fb4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005fce:	f5040513          	addi	a0,s0,-176
    80005fd2:	ffffe097          	auipc	ra,0xffffe
    80005fd6:	60a080e7          	jalr	1546(ra) # 800045dc <namei>
    80005fda:	84aa                	mv	s1,a0
    80005fdc:	c905                	beqz	a0,8000600c <sys_open+0x13c>
    ilock(ip);
    80005fde:	ffffe097          	auipc	ra,0xffffe
    80005fe2:	e58080e7          	jalr	-424(ra) # 80003e36 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005fe6:	04449703          	lh	a4,68(s1)
    80005fea:	4785                	li	a5,1
    80005fec:	f4f711e3          	bne	a4,a5,80005f2e <sys_open+0x5e>
    80005ff0:	f4c42783          	lw	a5,-180(s0)
    80005ff4:	d7b9                	beqz	a5,80005f42 <sys_open+0x72>
      iunlockput(ip);
    80005ff6:	8526                	mv	a0,s1
    80005ff8:	ffffe097          	auipc	ra,0xffffe
    80005ffc:	0a0080e7          	jalr	160(ra) # 80004098 <iunlockput>
      end_op();
    80006000:	fffff097          	auipc	ra,0xfffff
    80006004:	878080e7          	jalr	-1928(ra) # 80004878 <end_op>
      return -1;
    80006008:	557d                	li	a0,-1
    8000600a:	b76d                	j	80005fb4 <sys_open+0xe4>
      end_op();
    8000600c:	fffff097          	auipc	ra,0xfffff
    80006010:	86c080e7          	jalr	-1940(ra) # 80004878 <end_op>
      return -1;
    80006014:	557d                	li	a0,-1
    80006016:	bf79                	j	80005fb4 <sys_open+0xe4>
    iunlockput(ip);
    80006018:	8526                	mv	a0,s1
    8000601a:	ffffe097          	auipc	ra,0xffffe
    8000601e:	07e080e7          	jalr	126(ra) # 80004098 <iunlockput>
    end_op();
    80006022:	fffff097          	auipc	ra,0xfffff
    80006026:	856080e7          	jalr	-1962(ra) # 80004878 <end_op>
    return -1;
    8000602a:	557d                	li	a0,-1
    8000602c:	b761                	j	80005fb4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000602e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006032:	04649783          	lh	a5,70(s1)
    80006036:	02f99223          	sh	a5,36(s3)
    8000603a:	bf25                	j	80005f72 <sys_open+0xa2>
    itrunc(ip);
    8000603c:	8526                	mv	a0,s1
    8000603e:	ffffe097          	auipc	ra,0xffffe
    80006042:	f06080e7          	jalr	-250(ra) # 80003f44 <itrunc>
    80006046:	bfa9                	j	80005fa0 <sys_open+0xd0>
      fileclose(f);
    80006048:	854e                	mv	a0,s3
    8000604a:	fffff097          	auipc	ra,0xfffff
    8000604e:	c7a080e7          	jalr	-902(ra) # 80004cc4 <fileclose>
    iunlockput(ip);
    80006052:	8526                	mv	a0,s1
    80006054:	ffffe097          	auipc	ra,0xffffe
    80006058:	044080e7          	jalr	68(ra) # 80004098 <iunlockput>
    end_op();
    8000605c:	fffff097          	auipc	ra,0xfffff
    80006060:	81c080e7          	jalr	-2020(ra) # 80004878 <end_op>
    return -1;
    80006064:	557d                	li	a0,-1
    80006066:	b7b9                	j	80005fb4 <sys_open+0xe4>

0000000080006068 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006068:	7175                	addi	sp,sp,-144
    8000606a:	e506                	sd	ra,136(sp)
    8000606c:	e122                	sd	s0,128(sp)
    8000606e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006070:	ffffe097          	auipc	ra,0xffffe
    80006074:	788080e7          	jalr	1928(ra) # 800047f8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006078:	08000613          	li	a2,128
    8000607c:	f7040593          	addi	a1,s0,-144
    80006080:	4501                	li	a0,0
    80006082:	ffffd097          	auipc	ra,0xffffd
    80006086:	1ec080e7          	jalr	492(ra) # 8000326e <argstr>
    8000608a:	02054963          	bltz	a0,800060bc <sys_mkdir+0x54>
    8000608e:	4681                	li	a3,0
    80006090:	4601                	li	a2,0
    80006092:	4585                	li	a1,1
    80006094:	f7040513          	addi	a0,s0,-144
    80006098:	fffff097          	auipc	ra,0xfffff
    8000609c:	708080e7          	jalr	1800(ra) # 800057a0 <create>
    800060a0:	cd11                	beqz	a0,800060bc <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800060a2:	ffffe097          	auipc	ra,0xffffe
    800060a6:	ff6080e7          	jalr	-10(ra) # 80004098 <iunlockput>
  end_op();
    800060aa:	ffffe097          	auipc	ra,0xffffe
    800060ae:	7ce080e7          	jalr	1998(ra) # 80004878 <end_op>
  return 0;
    800060b2:	4501                	li	a0,0
}
    800060b4:	60aa                	ld	ra,136(sp)
    800060b6:	640a                	ld	s0,128(sp)
    800060b8:	6149                	addi	sp,sp,144
    800060ba:	8082                	ret
    end_op();
    800060bc:	ffffe097          	auipc	ra,0xffffe
    800060c0:	7bc080e7          	jalr	1980(ra) # 80004878 <end_op>
    return -1;
    800060c4:	557d                	li	a0,-1
    800060c6:	b7fd                	j	800060b4 <sys_mkdir+0x4c>

00000000800060c8 <sys_mknod>:

uint64
sys_mknod(void)
{
    800060c8:	7135                	addi	sp,sp,-160
    800060ca:	ed06                	sd	ra,152(sp)
    800060cc:	e922                	sd	s0,144(sp)
    800060ce:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800060d0:	ffffe097          	auipc	ra,0xffffe
    800060d4:	728080e7          	jalr	1832(ra) # 800047f8 <begin_op>
  argint(1, &major);
    800060d8:	f6c40593          	addi	a1,s0,-148
    800060dc:	4505                	li	a0,1
    800060de:	ffffd097          	auipc	ra,0xffffd
    800060e2:	150080e7          	jalr	336(ra) # 8000322e <argint>
  argint(2, &minor);
    800060e6:	f6840593          	addi	a1,s0,-152
    800060ea:	4509                	li	a0,2
    800060ec:	ffffd097          	auipc	ra,0xffffd
    800060f0:	142080e7          	jalr	322(ra) # 8000322e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060f4:	08000613          	li	a2,128
    800060f8:	f7040593          	addi	a1,s0,-144
    800060fc:	4501                	li	a0,0
    800060fe:	ffffd097          	auipc	ra,0xffffd
    80006102:	170080e7          	jalr	368(ra) # 8000326e <argstr>
    80006106:	02054b63          	bltz	a0,8000613c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000610a:	f6841683          	lh	a3,-152(s0)
    8000610e:	f6c41603          	lh	a2,-148(s0)
    80006112:	458d                	li	a1,3
    80006114:	f7040513          	addi	a0,s0,-144
    80006118:	fffff097          	auipc	ra,0xfffff
    8000611c:	688080e7          	jalr	1672(ra) # 800057a0 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006120:	cd11                	beqz	a0,8000613c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006122:	ffffe097          	auipc	ra,0xffffe
    80006126:	f76080e7          	jalr	-138(ra) # 80004098 <iunlockput>
  end_op();
    8000612a:	ffffe097          	auipc	ra,0xffffe
    8000612e:	74e080e7          	jalr	1870(ra) # 80004878 <end_op>
  return 0;
    80006132:	4501                	li	a0,0
}
    80006134:	60ea                	ld	ra,152(sp)
    80006136:	644a                	ld	s0,144(sp)
    80006138:	610d                	addi	sp,sp,160
    8000613a:	8082                	ret
    end_op();
    8000613c:	ffffe097          	auipc	ra,0xffffe
    80006140:	73c080e7          	jalr	1852(ra) # 80004878 <end_op>
    return -1;
    80006144:	557d                	li	a0,-1
    80006146:	b7fd                	j	80006134 <sys_mknod+0x6c>

0000000080006148 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006148:	7135                	addi	sp,sp,-160
    8000614a:	ed06                	sd	ra,152(sp)
    8000614c:	e922                	sd	s0,144(sp)
    8000614e:	e526                	sd	s1,136(sp)
    80006150:	e14a                	sd	s2,128(sp)
    80006152:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006154:	ffffc097          	auipc	ra,0xffffc
    80006158:	978080e7          	jalr	-1672(ra) # 80001acc <myproc>
    8000615c:	892a                	mv	s2,a0
  
  begin_op();
    8000615e:	ffffe097          	auipc	ra,0xffffe
    80006162:	69a080e7          	jalr	1690(ra) # 800047f8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006166:	08000613          	li	a2,128
    8000616a:	f6040593          	addi	a1,s0,-160
    8000616e:	4501                	li	a0,0
    80006170:	ffffd097          	auipc	ra,0xffffd
    80006174:	0fe080e7          	jalr	254(ra) # 8000326e <argstr>
    80006178:	04054b63          	bltz	a0,800061ce <sys_chdir+0x86>
    8000617c:	f6040513          	addi	a0,s0,-160
    80006180:	ffffe097          	auipc	ra,0xffffe
    80006184:	45c080e7          	jalr	1116(ra) # 800045dc <namei>
    80006188:	84aa                	mv	s1,a0
    8000618a:	c131                	beqz	a0,800061ce <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000618c:	ffffe097          	auipc	ra,0xffffe
    80006190:	caa080e7          	jalr	-854(ra) # 80003e36 <ilock>
  if(ip->type != T_DIR){
    80006194:	04449703          	lh	a4,68(s1)
    80006198:	4785                	li	a5,1
    8000619a:	04f71063          	bne	a4,a5,800061da <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000619e:	8526                	mv	a0,s1
    800061a0:	ffffe097          	auipc	ra,0xffffe
    800061a4:	d58080e7          	jalr	-680(ra) # 80003ef8 <iunlock>
  iput(p->cwd);
    800061a8:	15093503          	ld	a0,336(s2)
    800061ac:	ffffe097          	auipc	ra,0xffffe
    800061b0:	e44080e7          	jalr	-444(ra) # 80003ff0 <iput>
  end_op();
    800061b4:	ffffe097          	auipc	ra,0xffffe
    800061b8:	6c4080e7          	jalr	1732(ra) # 80004878 <end_op>
  p->cwd = ip;
    800061bc:	14993823          	sd	s1,336(s2)
  return 0;
    800061c0:	4501                	li	a0,0
}
    800061c2:	60ea                	ld	ra,152(sp)
    800061c4:	644a                	ld	s0,144(sp)
    800061c6:	64aa                	ld	s1,136(sp)
    800061c8:	690a                	ld	s2,128(sp)
    800061ca:	610d                	addi	sp,sp,160
    800061cc:	8082                	ret
    end_op();
    800061ce:	ffffe097          	auipc	ra,0xffffe
    800061d2:	6aa080e7          	jalr	1706(ra) # 80004878 <end_op>
    return -1;
    800061d6:	557d                	li	a0,-1
    800061d8:	b7ed                	j	800061c2 <sys_chdir+0x7a>
    iunlockput(ip);
    800061da:	8526                	mv	a0,s1
    800061dc:	ffffe097          	auipc	ra,0xffffe
    800061e0:	ebc080e7          	jalr	-324(ra) # 80004098 <iunlockput>
    end_op();
    800061e4:	ffffe097          	auipc	ra,0xffffe
    800061e8:	694080e7          	jalr	1684(ra) # 80004878 <end_op>
    return -1;
    800061ec:	557d                	li	a0,-1
    800061ee:	bfd1                	j	800061c2 <sys_chdir+0x7a>

00000000800061f0 <sys_exec>:

uint64
sys_exec(void)
{
    800061f0:	7145                	addi	sp,sp,-464
    800061f2:	e786                	sd	ra,456(sp)
    800061f4:	e3a2                	sd	s0,448(sp)
    800061f6:	ff26                	sd	s1,440(sp)
    800061f8:	fb4a                	sd	s2,432(sp)
    800061fa:	f74e                	sd	s3,424(sp)
    800061fc:	f352                	sd	s4,416(sp)
    800061fe:	ef56                	sd	s5,408(sp)
    80006200:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006202:	e3840593          	addi	a1,s0,-456
    80006206:	4505                	li	a0,1
    80006208:	ffffd097          	auipc	ra,0xffffd
    8000620c:	046080e7          	jalr	70(ra) # 8000324e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006210:	08000613          	li	a2,128
    80006214:	f4040593          	addi	a1,s0,-192
    80006218:	4501                	li	a0,0
    8000621a:	ffffd097          	auipc	ra,0xffffd
    8000621e:	054080e7          	jalr	84(ra) # 8000326e <argstr>
    80006222:	87aa                	mv	a5,a0
    return -1;
    80006224:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006226:	0c07c263          	bltz	a5,800062ea <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000622a:	10000613          	li	a2,256
    8000622e:	4581                	li	a1,0
    80006230:	e4040513          	addi	a0,s0,-448
    80006234:	ffffb097          	auipc	ra,0xffffb
    80006238:	b04080e7          	jalr	-1276(ra) # 80000d38 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000623c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006240:	89a6                	mv	s3,s1
    80006242:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006244:	02000a13          	li	s4,32
    80006248:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000624c:	00391793          	slli	a5,s2,0x3
    80006250:	e3040593          	addi	a1,s0,-464
    80006254:	e3843503          	ld	a0,-456(s0)
    80006258:	953e                	add	a0,a0,a5
    8000625a:	ffffd097          	auipc	ra,0xffffd
    8000625e:	f36080e7          	jalr	-202(ra) # 80003190 <fetchaddr>
    80006262:	02054a63          	bltz	a0,80006296 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006266:	e3043783          	ld	a5,-464(s0)
    8000626a:	c3b9                	beqz	a5,800062b0 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000626c:	ffffb097          	auipc	ra,0xffffb
    80006270:	8c0080e7          	jalr	-1856(ra) # 80000b2c <kalloc>
    80006274:	85aa                	mv	a1,a0
    80006276:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000627a:	cd11                	beqz	a0,80006296 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000627c:	6605                	lui	a2,0x1
    8000627e:	e3043503          	ld	a0,-464(s0)
    80006282:	ffffd097          	auipc	ra,0xffffd
    80006286:	f60080e7          	jalr	-160(ra) # 800031e2 <fetchstr>
    8000628a:	00054663          	bltz	a0,80006296 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    8000628e:	0905                	addi	s2,s2,1
    80006290:	09a1                	addi	s3,s3,8
    80006292:	fb491be3          	bne	s2,s4,80006248 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006296:	10048913          	addi	s2,s1,256
    8000629a:	6088                	ld	a0,0(s1)
    8000629c:	c531                	beqz	a0,800062e8 <sys_exec+0xf8>
    kfree(argv[i]);
    8000629e:	ffffa097          	auipc	ra,0xffffa
    800062a2:	74c080e7          	jalr	1868(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062a6:	04a1                	addi	s1,s1,8
    800062a8:	ff2499e3          	bne	s1,s2,8000629a <sys_exec+0xaa>
  return -1;
    800062ac:	557d                	li	a0,-1
    800062ae:	a835                	j	800062ea <sys_exec+0xfa>
      argv[i] = 0;
    800062b0:	0a8e                	slli	s5,s5,0x3
    800062b2:	fc040793          	addi	a5,s0,-64
    800062b6:	9abe                	add	s5,s5,a5
    800062b8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800062bc:	e4040593          	addi	a1,s0,-448
    800062c0:	f4040513          	addi	a0,s0,-192
    800062c4:	fffff097          	auipc	ra,0xfffff
    800062c8:	07a080e7          	jalr	122(ra) # 8000533e <exec>
    800062cc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062ce:	10048993          	addi	s3,s1,256
    800062d2:	6088                	ld	a0,0(s1)
    800062d4:	c901                	beqz	a0,800062e4 <sys_exec+0xf4>
    kfree(argv[i]);
    800062d6:	ffffa097          	auipc	ra,0xffffa
    800062da:	714080e7          	jalr	1812(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062de:	04a1                	addi	s1,s1,8
    800062e0:	ff3499e3          	bne	s1,s3,800062d2 <sys_exec+0xe2>
  return ret;
    800062e4:	854a                	mv	a0,s2
    800062e6:	a011                	j	800062ea <sys_exec+0xfa>
  return -1;
    800062e8:	557d                	li	a0,-1
}
    800062ea:	60be                	ld	ra,456(sp)
    800062ec:	641e                	ld	s0,448(sp)
    800062ee:	74fa                	ld	s1,440(sp)
    800062f0:	795a                	ld	s2,432(sp)
    800062f2:	79ba                	ld	s3,424(sp)
    800062f4:	7a1a                	ld	s4,416(sp)
    800062f6:	6afa                	ld	s5,408(sp)
    800062f8:	6179                	addi	sp,sp,464
    800062fa:	8082                	ret

00000000800062fc <sys_pipe>:

uint64
sys_pipe(void)
{
    800062fc:	7139                	addi	sp,sp,-64
    800062fe:	fc06                	sd	ra,56(sp)
    80006300:	f822                	sd	s0,48(sp)
    80006302:	f426                	sd	s1,40(sp)
    80006304:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006306:	ffffb097          	auipc	ra,0xffffb
    8000630a:	7c6080e7          	jalr	1990(ra) # 80001acc <myproc>
    8000630e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006310:	fd840593          	addi	a1,s0,-40
    80006314:	4501                	li	a0,0
    80006316:	ffffd097          	auipc	ra,0xffffd
    8000631a:	f38080e7          	jalr	-200(ra) # 8000324e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000631e:	fc840593          	addi	a1,s0,-56
    80006322:	fd040513          	addi	a0,s0,-48
    80006326:	fffff097          	auipc	ra,0xfffff
    8000632a:	cce080e7          	jalr	-818(ra) # 80004ff4 <pipealloc>
    return -1;
    8000632e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006330:	0c054463          	bltz	a0,800063f8 <sys_pipe+0xfc>
  fd0 = -1;
    80006334:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006338:	fd043503          	ld	a0,-48(s0)
    8000633c:	fffff097          	auipc	ra,0xfffff
    80006340:	422080e7          	jalr	1058(ra) # 8000575e <fdalloc>
    80006344:	fca42223          	sw	a0,-60(s0)
    80006348:	08054b63          	bltz	a0,800063de <sys_pipe+0xe2>
    8000634c:	fc843503          	ld	a0,-56(s0)
    80006350:	fffff097          	auipc	ra,0xfffff
    80006354:	40e080e7          	jalr	1038(ra) # 8000575e <fdalloc>
    80006358:	fca42023          	sw	a0,-64(s0)
    8000635c:	06054863          	bltz	a0,800063cc <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006360:	4691                	li	a3,4
    80006362:	fc440613          	addi	a2,s0,-60
    80006366:	fd843583          	ld	a1,-40(s0)
    8000636a:	68a8                	ld	a0,80(s1)
    8000636c:	ffffb097          	auipc	ra,0xffffb
    80006370:	388080e7          	jalr	904(ra) # 800016f4 <copyout>
    80006374:	02054063          	bltz	a0,80006394 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006378:	4691                	li	a3,4
    8000637a:	fc040613          	addi	a2,s0,-64
    8000637e:	fd843583          	ld	a1,-40(s0)
    80006382:	0591                	addi	a1,a1,4
    80006384:	68a8                	ld	a0,80(s1)
    80006386:	ffffb097          	auipc	ra,0xffffb
    8000638a:	36e080e7          	jalr	878(ra) # 800016f4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000638e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006390:	06055463          	bgez	a0,800063f8 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006394:	fc442783          	lw	a5,-60(s0)
    80006398:	07e9                	addi	a5,a5,26
    8000639a:	078e                	slli	a5,a5,0x3
    8000639c:	97a6                	add	a5,a5,s1
    8000639e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800063a2:	fc042503          	lw	a0,-64(s0)
    800063a6:	0569                	addi	a0,a0,26
    800063a8:	050e                	slli	a0,a0,0x3
    800063aa:	94aa                	add	s1,s1,a0
    800063ac:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800063b0:	fd043503          	ld	a0,-48(s0)
    800063b4:	fffff097          	auipc	ra,0xfffff
    800063b8:	910080e7          	jalr	-1776(ra) # 80004cc4 <fileclose>
    fileclose(wf);
    800063bc:	fc843503          	ld	a0,-56(s0)
    800063c0:	fffff097          	auipc	ra,0xfffff
    800063c4:	904080e7          	jalr	-1788(ra) # 80004cc4 <fileclose>
    return -1;
    800063c8:	57fd                	li	a5,-1
    800063ca:	a03d                	j	800063f8 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800063cc:	fc442783          	lw	a5,-60(s0)
    800063d0:	0007c763          	bltz	a5,800063de <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800063d4:	07e9                	addi	a5,a5,26
    800063d6:	078e                	slli	a5,a5,0x3
    800063d8:	94be                	add	s1,s1,a5
    800063da:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800063de:	fd043503          	ld	a0,-48(s0)
    800063e2:	fffff097          	auipc	ra,0xfffff
    800063e6:	8e2080e7          	jalr	-1822(ra) # 80004cc4 <fileclose>
    fileclose(wf);
    800063ea:	fc843503          	ld	a0,-56(s0)
    800063ee:	fffff097          	auipc	ra,0xfffff
    800063f2:	8d6080e7          	jalr	-1834(ra) # 80004cc4 <fileclose>
    return -1;
    800063f6:	57fd                	li	a5,-1
}
    800063f8:	853e                	mv	a0,a5
    800063fa:	70e2                	ld	ra,56(sp)
    800063fc:	7442                	ld	s0,48(sp)
    800063fe:	74a2                	ld	s1,40(sp)
    80006400:	6121                	addi	sp,sp,64
    80006402:	8082                	ret
	...

0000000080006410 <kernelvec>:
    80006410:	7111                	addi	sp,sp,-256
    80006412:	e006                	sd	ra,0(sp)
    80006414:	e40a                	sd	sp,8(sp)
    80006416:	e80e                	sd	gp,16(sp)
    80006418:	ec12                	sd	tp,24(sp)
    8000641a:	f016                	sd	t0,32(sp)
    8000641c:	f41a                	sd	t1,40(sp)
    8000641e:	f81e                	sd	t2,48(sp)
    80006420:	fc22                	sd	s0,56(sp)
    80006422:	e0a6                	sd	s1,64(sp)
    80006424:	e4aa                	sd	a0,72(sp)
    80006426:	e8ae                	sd	a1,80(sp)
    80006428:	ecb2                	sd	a2,88(sp)
    8000642a:	f0b6                	sd	a3,96(sp)
    8000642c:	f4ba                	sd	a4,104(sp)
    8000642e:	f8be                	sd	a5,112(sp)
    80006430:	fcc2                	sd	a6,120(sp)
    80006432:	e146                	sd	a7,128(sp)
    80006434:	e54a                	sd	s2,136(sp)
    80006436:	e94e                	sd	s3,144(sp)
    80006438:	ed52                	sd	s4,152(sp)
    8000643a:	f156                	sd	s5,160(sp)
    8000643c:	f55a                	sd	s6,168(sp)
    8000643e:	f95e                	sd	s7,176(sp)
    80006440:	fd62                	sd	s8,184(sp)
    80006442:	e1e6                	sd	s9,192(sp)
    80006444:	e5ea                	sd	s10,200(sp)
    80006446:	e9ee                	sd	s11,208(sp)
    80006448:	edf2                	sd	t3,216(sp)
    8000644a:	f1f6                	sd	t4,224(sp)
    8000644c:	f5fa                	sd	t5,232(sp)
    8000644e:	f9fe                	sd	t6,240(sp)
    80006450:	bf3fc0ef          	jal	ra,80003042 <kerneltrap>
    80006454:	6082                	ld	ra,0(sp)
    80006456:	6122                	ld	sp,8(sp)
    80006458:	61c2                	ld	gp,16(sp)
    8000645a:	7282                	ld	t0,32(sp)
    8000645c:	7322                	ld	t1,40(sp)
    8000645e:	73c2                	ld	t2,48(sp)
    80006460:	7462                	ld	s0,56(sp)
    80006462:	6486                	ld	s1,64(sp)
    80006464:	6526                	ld	a0,72(sp)
    80006466:	65c6                	ld	a1,80(sp)
    80006468:	6666                	ld	a2,88(sp)
    8000646a:	7686                	ld	a3,96(sp)
    8000646c:	7726                	ld	a4,104(sp)
    8000646e:	77c6                	ld	a5,112(sp)
    80006470:	7866                	ld	a6,120(sp)
    80006472:	688a                	ld	a7,128(sp)
    80006474:	692a                	ld	s2,136(sp)
    80006476:	69ca                	ld	s3,144(sp)
    80006478:	6a6a                	ld	s4,152(sp)
    8000647a:	7a8a                	ld	s5,160(sp)
    8000647c:	7b2a                	ld	s6,168(sp)
    8000647e:	7bca                	ld	s7,176(sp)
    80006480:	7c6a                	ld	s8,184(sp)
    80006482:	6c8e                	ld	s9,192(sp)
    80006484:	6d2e                	ld	s10,200(sp)
    80006486:	6dce                	ld	s11,208(sp)
    80006488:	6e6e                	ld	t3,216(sp)
    8000648a:	7e8e                	ld	t4,224(sp)
    8000648c:	7f2e                	ld	t5,232(sp)
    8000648e:	7fce                	ld	t6,240(sp)
    80006490:	6111                	addi	sp,sp,256
    80006492:	10200073          	sret
    80006496:	00000013          	nop
    8000649a:	00000013          	nop
    8000649e:	0001                	nop

00000000800064a0 <timervec>:
    800064a0:	34051573          	csrrw	a0,mscratch,a0
    800064a4:	e10c                	sd	a1,0(a0)
    800064a6:	e510                	sd	a2,8(a0)
    800064a8:	e914                	sd	a3,16(a0)
    800064aa:	6d0c                	ld	a1,24(a0)
    800064ac:	7110                	ld	a2,32(a0)
    800064ae:	6194                	ld	a3,0(a1)
    800064b0:	96b2                	add	a3,a3,a2
    800064b2:	e194                	sd	a3,0(a1)
    800064b4:	4589                	li	a1,2
    800064b6:	14459073          	csrw	sip,a1
    800064ba:	6914                	ld	a3,16(a0)
    800064bc:	6510                	ld	a2,8(a0)
    800064be:	610c                	ld	a1,0(a0)
    800064c0:	34051573          	csrrw	a0,mscratch,a0
    800064c4:	30200073          	mret
	...

00000000800064ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800064ca:	1141                	addi	sp,sp,-16
    800064cc:	e422                	sd	s0,8(sp)
    800064ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800064d0:	0c0007b7          	lui	a5,0xc000
    800064d4:	4705                	li	a4,1
    800064d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800064d8:	c3d8                	sw	a4,4(a5)
}
    800064da:	6422                	ld	s0,8(sp)
    800064dc:	0141                	addi	sp,sp,16
    800064de:	8082                	ret

00000000800064e0 <plicinithart>:

void
plicinithart(void)
{
    800064e0:	1141                	addi	sp,sp,-16
    800064e2:	e406                	sd	ra,8(sp)
    800064e4:	e022                	sd	s0,0(sp)
    800064e6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064e8:	ffffb097          	auipc	ra,0xffffb
    800064ec:	5b8080e7          	jalr	1464(ra) # 80001aa0 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800064f0:	0085171b          	slliw	a4,a0,0x8
    800064f4:	0c0027b7          	lui	a5,0xc002
    800064f8:	97ba                	add	a5,a5,a4
    800064fa:	40200713          	li	a4,1026
    800064fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006502:	00d5151b          	slliw	a0,a0,0xd
    80006506:	0c2017b7          	lui	a5,0xc201
    8000650a:	953e                	add	a0,a0,a5
    8000650c:	00052023          	sw	zero,0(a0)
}
    80006510:	60a2                	ld	ra,8(sp)
    80006512:	6402                	ld	s0,0(sp)
    80006514:	0141                	addi	sp,sp,16
    80006516:	8082                	ret

0000000080006518 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006518:	1141                	addi	sp,sp,-16
    8000651a:	e406                	sd	ra,8(sp)
    8000651c:	e022                	sd	s0,0(sp)
    8000651e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006520:	ffffb097          	auipc	ra,0xffffb
    80006524:	580080e7          	jalr	1408(ra) # 80001aa0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006528:	00d5179b          	slliw	a5,a0,0xd
    8000652c:	0c201537          	lui	a0,0xc201
    80006530:	953e                	add	a0,a0,a5
  return irq;
}
    80006532:	4148                	lw	a0,4(a0)
    80006534:	60a2                	ld	ra,8(sp)
    80006536:	6402                	ld	s0,0(sp)
    80006538:	0141                	addi	sp,sp,16
    8000653a:	8082                	ret

000000008000653c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000653c:	1101                	addi	sp,sp,-32
    8000653e:	ec06                	sd	ra,24(sp)
    80006540:	e822                	sd	s0,16(sp)
    80006542:	e426                	sd	s1,8(sp)
    80006544:	1000                	addi	s0,sp,32
    80006546:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006548:	ffffb097          	auipc	ra,0xffffb
    8000654c:	558080e7          	jalr	1368(ra) # 80001aa0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006550:	00d5151b          	slliw	a0,a0,0xd
    80006554:	0c2017b7          	lui	a5,0xc201
    80006558:	97aa                	add	a5,a5,a0
    8000655a:	c3c4                	sw	s1,4(a5)
}
    8000655c:	60e2                	ld	ra,24(sp)
    8000655e:	6442                	ld	s0,16(sp)
    80006560:	64a2                	ld	s1,8(sp)
    80006562:	6105                	addi	sp,sp,32
    80006564:	8082                	ret

0000000080006566 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006566:	1141                	addi	sp,sp,-16
    80006568:	e406                	sd	ra,8(sp)
    8000656a:	e022                	sd	s0,0(sp)
    8000656c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000656e:	479d                	li	a5,7
    80006570:	04a7cc63          	blt	a5,a0,800065c8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006574:	0023c797          	auipc	a5,0x23c
    80006578:	2c478793          	addi	a5,a5,708 # 80242838 <disk>
    8000657c:	97aa                	add	a5,a5,a0
    8000657e:	0187c783          	lbu	a5,24(a5)
    80006582:	ebb9                	bnez	a5,800065d8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006584:	00451613          	slli	a2,a0,0x4
    80006588:	0023c797          	auipc	a5,0x23c
    8000658c:	2b078793          	addi	a5,a5,688 # 80242838 <disk>
    80006590:	6394                	ld	a3,0(a5)
    80006592:	96b2                	add	a3,a3,a2
    80006594:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006598:	6398                	ld	a4,0(a5)
    8000659a:	9732                	add	a4,a4,a2
    8000659c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800065a0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800065a4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800065a8:	953e                	add	a0,a0,a5
    800065aa:	4785                	li	a5,1
    800065ac:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800065b0:	0023c517          	auipc	a0,0x23c
    800065b4:	2a050513          	addi	a0,a0,672 # 80242850 <disk+0x18>
    800065b8:	ffffc097          	auipc	ra,0xffffc
    800065bc:	f9e080e7          	jalr	-98(ra) # 80002556 <wakeup>
}
    800065c0:	60a2                	ld	ra,8(sp)
    800065c2:	6402                	ld	s0,0(sp)
    800065c4:	0141                	addi	sp,sp,16
    800065c6:	8082                	ret
    panic("free_desc 1");
    800065c8:	00002517          	auipc	a0,0x2
    800065cc:	19050513          	addi	a0,a0,400 # 80008758 <syscalls+0x308>
    800065d0:	ffffa097          	auipc	ra,0xffffa
    800065d4:	f6e080e7          	jalr	-146(ra) # 8000053e <panic>
    panic("free_desc 2");
    800065d8:	00002517          	auipc	a0,0x2
    800065dc:	19050513          	addi	a0,a0,400 # 80008768 <syscalls+0x318>
    800065e0:	ffffa097          	auipc	ra,0xffffa
    800065e4:	f5e080e7          	jalr	-162(ra) # 8000053e <panic>

00000000800065e8 <virtio_disk_init>:
{
    800065e8:	1101                	addi	sp,sp,-32
    800065ea:	ec06                	sd	ra,24(sp)
    800065ec:	e822                	sd	s0,16(sp)
    800065ee:	e426                	sd	s1,8(sp)
    800065f0:	e04a                	sd	s2,0(sp)
    800065f2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800065f4:	00002597          	auipc	a1,0x2
    800065f8:	18458593          	addi	a1,a1,388 # 80008778 <syscalls+0x328>
    800065fc:	0023c517          	auipc	a0,0x23c
    80006600:	36450513          	addi	a0,a0,868 # 80242960 <disk+0x128>
    80006604:	ffffa097          	auipc	ra,0xffffa
    80006608:	5a8080e7          	jalr	1448(ra) # 80000bac <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000660c:	100017b7          	lui	a5,0x10001
    80006610:	4398                	lw	a4,0(a5)
    80006612:	2701                	sext.w	a4,a4
    80006614:	747277b7          	lui	a5,0x74727
    80006618:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000661c:	14f71c63          	bne	a4,a5,80006774 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006620:	100017b7          	lui	a5,0x10001
    80006624:	43dc                	lw	a5,4(a5)
    80006626:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006628:	4709                	li	a4,2
    8000662a:	14e79563          	bne	a5,a4,80006774 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000662e:	100017b7          	lui	a5,0x10001
    80006632:	479c                	lw	a5,8(a5)
    80006634:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006636:	12e79f63          	bne	a5,a4,80006774 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000663a:	100017b7          	lui	a5,0x10001
    8000663e:	47d8                	lw	a4,12(a5)
    80006640:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006642:	554d47b7          	lui	a5,0x554d4
    80006646:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000664a:	12f71563          	bne	a4,a5,80006774 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000664e:	100017b7          	lui	a5,0x10001
    80006652:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006656:	4705                	li	a4,1
    80006658:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000665a:	470d                	li	a4,3
    8000665c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000665e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006660:	c7ffe737          	lui	a4,0xc7ffe
    80006664:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47dbbde7>
    80006668:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000666a:	2701                	sext.w	a4,a4
    8000666c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000666e:	472d                	li	a4,11
    80006670:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006672:	5bbc                	lw	a5,112(a5)
    80006674:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006678:	8ba1                	andi	a5,a5,8
    8000667a:	10078563          	beqz	a5,80006784 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000667e:	100017b7          	lui	a5,0x10001
    80006682:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006686:	43fc                	lw	a5,68(a5)
    80006688:	2781                	sext.w	a5,a5
    8000668a:	10079563          	bnez	a5,80006794 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000668e:	100017b7          	lui	a5,0x10001
    80006692:	5bdc                	lw	a5,52(a5)
    80006694:	2781                	sext.w	a5,a5
  if(max == 0)
    80006696:	10078763          	beqz	a5,800067a4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000669a:	471d                	li	a4,7
    8000669c:	10f77c63          	bgeu	a4,a5,800067b4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    800066a0:	ffffa097          	auipc	ra,0xffffa
    800066a4:	48c080e7          	jalr	1164(ra) # 80000b2c <kalloc>
    800066a8:	0023c497          	auipc	s1,0x23c
    800066ac:	19048493          	addi	s1,s1,400 # 80242838 <disk>
    800066b0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800066b2:	ffffa097          	auipc	ra,0xffffa
    800066b6:	47a080e7          	jalr	1146(ra) # 80000b2c <kalloc>
    800066ba:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800066bc:	ffffa097          	auipc	ra,0xffffa
    800066c0:	470080e7          	jalr	1136(ra) # 80000b2c <kalloc>
    800066c4:	87aa                	mv	a5,a0
    800066c6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800066c8:	6088                	ld	a0,0(s1)
    800066ca:	cd6d                	beqz	a0,800067c4 <virtio_disk_init+0x1dc>
    800066cc:	0023c717          	auipc	a4,0x23c
    800066d0:	17473703          	ld	a4,372(a4) # 80242840 <disk+0x8>
    800066d4:	cb65                	beqz	a4,800067c4 <virtio_disk_init+0x1dc>
    800066d6:	c7fd                	beqz	a5,800067c4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    800066d8:	6605                	lui	a2,0x1
    800066da:	4581                	li	a1,0
    800066dc:	ffffa097          	auipc	ra,0xffffa
    800066e0:	65c080e7          	jalr	1628(ra) # 80000d38 <memset>
  memset(disk.avail, 0, PGSIZE);
    800066e4:	0023c497          	auipc	s1,0x23c
    800066e8:	15448493          	addi	s1,s1,340 # 80242838 <disk>
    800066ec:	6605                	lui	a2,0x1
    800066ee:	4581                	li	a1,0
    800066f0:	6488                	ld	a0,8(s1)
    800066f2:	ffffa097          	auipc	ra,0xffffa
    800066f6:	646080e7          	jalr	1606(ra) # 80000d38 <memset>
  memset(disk.used, 0, PGSIZE);
    800066fa:	6605                	lui	a2,0x1
    800066fc:	4581                	li	a1,0
    800066fe:	6888                	ld	a0,16(s1)
    80006700:	ffffa097          	auipc	ra,0xffffa
    80006704:	638080e7          	jalr	1592(ra) # 80000d38 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006708:	100017b7          	lui	a5,0x10001
    8000670c:	4721                	li	a4,8
    8000670e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006710:	4098                	lw	a4,0(s1)
    80006712:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006716:	40d8                	lw	a4,4(s1)
    80006718:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000671c:	6498                	ld	a4,8(s1)
    8000671e:	0007069b          	sext.w	a3,a4
    80006722:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006726:	9701                	srai	a4,a4,0x20
    80006728:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000672c:	6898                	ld	a4,16(s1)
    8000672e:	0007069b          	sext.w	a3,a4
    80006732:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006736:	9701                	srai	a4,a4,0x20
    80006738:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000673c:	4705                	li	a4,1
    8000673e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006740:	00e48c23          	sb	a4,24(s1)
    80006744:	00e48ca3          	sb	a4,25(s1)
    80006748:	00e48d23          	sb	a4,26(s1)
    8000674c:	00e48da3          	sb	a4,27(s1)
    80006750:	00e48e23          	sb	a4,28(s1)
    80006754:	00e48ea3          	sb	a4,29(s1)
    80006758:	00e48f23          	sb	a4,30(s1)
    8000675c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006760:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006764:	0727a823          	sw	s2,112(a5)
}
    80006768:	60e2                	ld	ra,24(sp)
    8000676a:	6442                	ld	s0,16(sp)
    8000676c:	64a2                	ld	s1,8(sp)
    8000676e:	6902                	ld	s2,0(sp)
    80006770:	6105                	addi	sp,sp,32
    80006772:	8082                	ret
    panic("could not find virtio disk");
    80006774:	00002517          	auipc	a0,0x2
    80006778:	01450513          	addi	a0,a0,20 # 80008788 <syscalls+0x338>
    8000677c:	ffffa097          	auipc	ra,0xffffa
    80006780:	dc2080e7          	jalr	-574(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006784:	00002517          	auipc	a0,0x2
    80006788:	02450513          	addi	a0,a0,36 # 800087a8 <syscalls+0x358>
    8000678c:	ffffa097          	auipc	ra,0xffffa
    80006790:	db2080e7          	jalr	-590(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006794:	00002517          	auipc	a0,0x2
    80006798:	03450513          	addi	a0,a0,52 # 800087c8 <syscalls+0x378>
    8000679c:	ffffa097          	auipc	ra,0xffffa
    800067a0:	da2080e7          	jalr	-606(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800067a4:	00002517          	auipc	a0,0x2
    800067a8:	04450513          	addi	a0,a0,68 # 800087e8 <syscalls+0x398>
    800067ac:	ffffa097          	auipc	ra,0xffffa
    800067b0:	d92080e7          	jalr	-622(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800067b4:	00002517          	auipc	a0,0x2
    800067b8:	05450513          	addi	a0,a0,84 # 80008808 <syscalls+0x3b8>
    800067bc:	ffffa097          	auipc	ra,0xffffa
    800067c0:	d82080e7          	jalr	-638(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    800067c4:	00002517          	auipc	a0,0x2
    800067c8:	06450513          	addi	a0,a0,100 # 80008828 <syscalls+0x3d8>
    800067cc:	ffffa097          	auipc	ra,0xffffa
    800067d0:	d72080e7          	jalr	-654(ra) # 8000053e <panic>

00000000800067d4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800067d4:	7119                	addi	sp,sp,-128
    800067d6:	fc86                	sd	ra,120(sp)
    800067d8:	f8a2                	sd	s0,112(sp)
    800067da:	f4a6                	sd	s1,104(sp)
    800067dc:	f0ca                	sd	s2,96(sp)
    800067de:	ecce                	sd	s3,88(sp)
    800067e0:	e8d2                	sd	s4,80(sp)
    800067e2:	e4d6                	sd	s5,72(sp)
    800067e4:	e0da                	sd	s6,64(sp)
    800067e6:	fc5e                	sd	s7,56(sp)
    800067e8:	f862                	sd	s8,48(sp)
    800067ea:	f466                	sd	s9,40(sp)
    800067ec:	f06a                	sd	s10,32(sp)
    800067ee:	ec6e                	sd	s11,24(sp)
    800067f0:	0100                	addi	s0,sp,128
    800067f2:	8aaa                	mv	s5,a0
    800067f4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800067f6:	00c52d03          	lw	s10,12(a0)
    800067fa:	001d1d1b          	slliw	s10,s10,0x1
    800067fe:	1d02                	slli	s10,s10,0x20
    80006800:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006804:	0023c517          	auipc	a0,0x23c
    80006808:	15c50513          	addi	a0,a0,348 # 80242960 <disk+0x128>
    8000680c:	ffffa097          	auipc	ra,0xffffa
    80006810:	430080e7          	jalr	1072(ra) # 80000c3c <acquire>
  for(int i = 0; i < 3; i++){
    80006814:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006816:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006818:	0023cb97          	auipc	s7,0x23c
    8000681c:	020b8b93          	addi	s7,s7,32 # 80242838 <disk>
  for(int i = 0; i < 3; i++){
    80006820:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006822:	0023cc97          	auipc	s9,0x23c
    80006826:	13ec8c93          	addi	s9,s9,318 # 80242960 <disk+0x128>
    8000682a:	a08d                	j	8000688c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000682c:	00fb8733          	add	a4,s7,a5
    80006830:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006834:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006836:	0207c563          	bltz	a5,80006860 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000683a:	2905                	addiw	s2,s2,1
    8000683c:	0611                	addi	a2,a2,4
    8000683e:	05690c63          	beq	s2,s6,80006896 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006842:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006844:	0023c717          	auipc	a4,0x23c
    80006848:	ff470713          	addi	a4,a4,-12 # 80242838 <disk>
    8000684c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000684e:	01874683          	lbu	a3,24(a4)
    80006852:	fee9                	bnez	a3,8000682c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006854:	2785                	addiw	a5,a5,1
    80006856:	0705                	addi	a4,a4,1
    80006858:	fe979be3          	bne	a5,s1,8000684e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000685c:	57fd                	li	a5,-1
    8000685e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006860:	01205d63          	blez	s2,8000687a <virtio_disk_rw+0xa6>
    80006864:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006866:	000a2503          	lw	a0,0(s4)
    8000686a:	00000097          	auipc	ra,0x0
    8000686e:	cfc080e7          	jalr	-772(ra) # 80006566 <free_desc>
      for(int j = 0; j < i; j++)
    80006872:	2d85                	addiw	s11,s11,1
    80006874:	0a11                	addi	s4,s4,4
    80006876:	ffb918e3          	bne	s2,s11,80006866 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000687a:	85e6                	mv	a1,s9
    8000687c:	0023c517          	auipc	a0,0x23c
    80006880:	fd450513          	addi	a0,a0,-44 # 80242850 <disk+0x18>
    80006884:	ffffc097          	auipc	ra,0xffffc
    80006888:	c6e080e7          	jalr	-914(ra) # 800024f2 <sleep>
  for(int i = 0; i < 3; i++){
    8000688c:	f8040a13          	addi	s4,s0,-128
{
    80006890:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006892:	894e                	mv	s2,s3
    80006894:	b77d                	j	80006842 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006896:	f8042583          	lw	a1,-128(s0)
    8000689a:	00a58793          	addi	a5,a1,10
    8000689e:	0792                	slli	a5,a5,0x4

  if(write)
    800068a0:	0023c617          	auipc	a2,0x23c
    800068a4:	f9860613          	addi	a2,a2,-104 # 80242838 <disk>
    800068a8:	00f60733          	add	a4,a2,a5
    800068ac:	018036b3          	snez	a3,s8
    800068b0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800068b2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800068b6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800068ba:	f6078693          	addi	a3,a5,-160
    800068be:	6218                	ld	a4,0(a2)
    800068c0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800068c2:	00878513          	addi	a0,a5,8
    800068c6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800068c8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800068ca:	6208                	ld	a0,0(a2)
    800068cc:	96aa                	add	a3,a3,a0
    800068ce:	4741                	li	a4,16
    800068d0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800068d2:	4705                	li	a4,1
    800068d4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800068d8:	f8442703          	lw	a4,-124(s0)
    800068dc:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800068e0:	0712                	slli	a4,a4,0x4
    800068e2:	953a                	add	a0,a0,a4
    800068e4:	058a8693          	addi	a3,s5,88
    800068e8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800068ea:	6208                	ld	a0,0(a2)
    800068ec:	972a                	add	a4,a4,a0
    800068ee:	40000693          	li	a3,1024
    800068f2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800068f4:	001c3c13          	seqz	s8,s8
    800068f8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800068fa:	001c6c13          	ori	s8,s8,1
    800068fe:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006902:	f8842603          	lw	a2,-120(s0)
    80006906:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000690a:	0023c697          	auipc	a3,0x23c
    8000690e:	f2e68693          	addi	a3,a3,-210 # 80242838 <disk>
    80006912:	00258713          	addi	a4,a1,2
    80006916:	0712                	slli	a4,a4,0x4
    80006918:	9736                	add	a4,a4,a3
    8000691a:	587d                	li	a6,-1
    8000691c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006920:	0612                	slli	a2,a2,0x4
    80006922:	9532                	add	a0,a0,a2
    80006924:	f9078793          	addi	a5,a5,-112
    80006928:	97b6                	add	a5,a5,a3
    8000692a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000692c:	629c                	ld	a5,0(a3)
    8000692e:	97b2                	add	a5,a5,a2
    80006930:	4605                	li	a2,1
    80006932:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006934:	4509                	li	a0,2
    80006936:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000693a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000693e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006942:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006946:	6698                	ld	a4,8(a3)
    80006948:	00275783          	lhu	a5,2(a4)
    8000694c:	8b9d                	andi	a5,a5,7
    8000694e:	0786                	slli	a5,a5,0x1
    80006950:	97ba                	add	a5,a5,a4
    80006952:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006956:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000695a:	6698                	ld	a4,8(a3)
    8000695c:	00275783          	lhu	a5,2(a4)
    80006960:	2785                	addiw	a5,a5,1
    80006962:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006966:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000696a:	100017b7          	lui	a5,0x10001
    8000696e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006972:	004aa783          	lw	a5,4(s5)
    80006976:	02c79163          	bne	a5,a2,80006998 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000697a:	0023c917          	auipc	s2,0x23c
    8000697e:	fe690913          	addi	s2,s2,-26 # 80242960 <disk+0x128>
  while(b->disk == 1) {
    80006982:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006984:	85ca                	mv	a1,s2
    80006986:	8556                	mv	a0,s5
    80006988:	ffffc097          	auipc	ra,0xffffc
    8000698c:	b6a080e7          	jalr	-1174(ra) # 800024f2 <sleep>
  while(b->disk == 1) {
    80006990:	004aa783          	lw	a5,4(s5)
    80006994:	fe9788e3          	beq	a5,s1,80006984 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006998:	f8042903          	lw	s2,-128(s0)
    8000699c:	00290793          	addi	a5,s2,2
    800069a0:	00479713          	slli	a4,a5,0x4
    800069a4:	0023c797          	auipc	a5,0x23c
    800069a8:	e9478793          	addi	a5,a5,-364 # 80242838 <disk>
    800069ac:	97ba                	add	a5,a5,a4
    800069ae:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800069b2:	0023c997          	auipc	s3,0x23c
    800069b6:	e8698993          	addi	s3,s3,-378 # 80242838 <disk>
    800069ba:	00491713          	slli	a4,s2,0x4
    800069be:	0009b783          	ld	a5,0(s3)
    800069c2:	97ba                	add	a5,a5,a4
    800069c4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800069c8:	854a                	mv	a0,s2
    800069ca:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800069ce:	00000097          	auipc	ra,0x0
    800069d2:	b98080e7          	jalr	-1128(ra) # 80006566 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800069d6:	8885                	andi	s1,s1,1
    800069d8:	f0ed                	bnez	s1,800069ba <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800069da:	0023c517          	auipc	a0,0x23c
    800069de:	f8650513          	addi	a0,a0,-122 # 80242960 <disk+0x128>
    800069e2:	ffffa097          	auipc	ra,0xffffa
    800069e6:	30e080e7          	jalr	782(ra) # 80000cf0 <release>
}
    800069ea:	70e6                	ld	ra,120(sp)
    800069ec:	7446                	ld	s0,112(sp)
    800069ee:	74a6                	ld	s1,104(sp)
    800069f0:	7906                	ld	s2,96(sp)
    800069f2:	69e6                	ld	s3,88(sp)
    800069f4:	6a46                	ld	s4,80(sp)
    800069f6:	6aa6                	ld	s5,72(sp)
    800069f8:	6b06                	ld	s6,64(sp)
    800069fa:	7be2                	ld	s7,56(sp)
    800069fc:	7c42                	ld	s8,48(sp)
    800069fe:	7ca2                	ld	s9,40(sp)
    80006a00:	7d02                	ld	s10,32(sp)
    80006a02:	6de2                	ld	s11,24(sp)
    80006a04:	6109                	addi	sp,sp,128
    80006a06:	8082                	ret

0000000080006a08 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006a08:	1101                	addi	sp,sp,-32
    80006a0a:	ec06                	sd	ra,24(sp)
    80006a0c:	e822                	sd	s0,16(sp)
    80006a0e:	e426                	sd	s1,8(sp)
    80006a10:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006a12:	0023c497          	auipc	s1,0x23c
    80006a16:	e2648493          	addi	s1,s1,-474 # 80242838 <disk>
    80006a1a:	0023c517          	auipc	a0,0x23c
    80006a1e:	f4650513          	addi	a0,a0,-186 # 80242960 <disk+0x128>
    80006a22:	ffffa097          	auipc	ra,0xffffa
    80006a26:	21a080e7          	jalr	538(ra) # 80000c3c <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006a2a:	10001737          	lui	a4,0x10001
    80006a2e:	533c                	lw	a5,96(a4)
    80006a30:	8b8d                	andi	a5,a5,3
    80006a32:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006a34:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006a38:	689c                	ld	a5,16(s1)
    80006a3a:	0204d703          	lhu	a4,32(s1)
    80006a3e:	0027d783          	lhu	a5,2(a5)
    80006a42:	04f70863          	beq	a4,a5,80006a92 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006a46:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006a4a:	6898                	ld	a4,16(s1)
    80006a4c:	0204d783          	lhu	a5,32(s1)
    80006a50:	8b9d                	andi	a5,a5,7
    80006a52:	078e                	slli	a5,a5,0x3
    80006a54:	97ba                	add	a5,a5,a4
    80006a56:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006a58:	00278713          	addi	a4,a5,2
    80006a5c:	0712                	slli	a4,a4,0x4
    80006a5e:	9726                	add	a4,a4,s1
    80006a60:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006a64:	e721                	bnez	a4,80006aac <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006a66:	0789                	addi	a5,a5,2
    80006a68:	0792                	slli	a5,a5,0x4
    80006a6a:	97a6                	add	a5,a5,s1
    80006a6c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006a6e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006a72:	ffffc097          	auipc	ra,0xffffc
    80006a76:	ae4080e7          	jalr	-1308(ra) # 80002556 <wakeup>

    disk.used_idx += 1;
    80006a7a:	0204d783          	lhu	a5,32(s1)
    80006a7e:	2785                	addiw	a5,a5,1
    80006a80:	17c2                	slli	a5,a5,0x30
    80006a82:	93c1                	srli	a5,a5,0x30
    80006a84:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006a88:	6898                	ld	a4,16(s1)
    80006a8a:	00275703          	lhu	a4,2(a4)
    80006a8e:	faf71ce3          	bne	a4,a5,80006a46 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006a92:	0023c517          	auipc	a0,0x23c
    80006a96:	ece50513          	addi	a0,a0,-306 # 80242960 <disk+0x128>
    80006a9a:	ffffa097          	auipc	ra,0xffffa
    80006a9e:	256080e7          	jalr	598(ra) # 80000cf0 <release>
}
    80006aa2:	60e2                	ld	ra,24(sp)
    80006aa4:	6442                	ld	s0,16(sp)
    80006aa6:	64a2                	ld	s1,8(sp)
    80006aa8:	6105                	addi	sp,sp,32
    80006aaa:	8082                	ret
      panic("virtio_disk_intr status");
    80006aac:	00002517          	auipc	a0,0x2
    80006ab0:	d9450513          	addi	a0,a0,-620 # 80008840 <syscalls+0x3f0>
    80006ab4:	ffffa097          	auipc	ra,0xffffa
    80006ab8:	a8a080e7          	jalr	-1398(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
