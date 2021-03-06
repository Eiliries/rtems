@c
@c  COPYRIGHT (c) 1988-2008.
@c  On-Line Applications Research Corporation (OAR).
@c  All rights reserved.

@chapter Initialization Code

@section Introduction

The initialization code is the first piece of code executed when there's a
reset/reboot. Its purpose is to initialize the board for the application.
This chapter contains a narrative description of the initialization
process followed by a description of each of the files and routines
commonly found in the BSP related to initialization.  The remainder of
this chapter covers special issues which require attention such
as interrupt vector table and chip select initialization.

Most of the examples in this chapter will be based on the SPARC/ERC32 and
m68k/gen68340 BSP initialization code.  Like most BSPs, the initialization
for these BSP is divided into two subdirectories under the BSP source
directory.  The BSP source code for these BSPs is in the following
directories:

@example
c/src/lib/libbsp/m68k/gen68340
c/src/lib/libbsp/sparc/erc32
@end example

Both BSPs contain startup code written in assembly language and C.
The gen68340 BSP has its early initialization start code in the
@code{start340} subdirectory and its C startup code in the @code{startup}
directory.  In the @code{start340} directory are two source files.
The file @code{startfor340only.s} is the simpler of these files as it only
has initialization code for a MC68340 board.  The file @code{start340.s}
contains initialization for a 68349 based board as well.

Similarly, the ERC32 BSP has startup code written in assembly language
and C.  However, this BSP shares this code with other SPARC BSPs.
Thus the @code{Makefile.am} explicitly references the following files
for this functionality.

@example
../../sparc/shared/start.S
@end example

@b{NOTE:} In most BSPs, the directory named @code{start340} in the
gen68340 BSP would be simply named @code{start} or start followed by a
BSP designation.

@section Required Global Variables

Although not strictly part of initialization, there are a few global
variables assumed to exist by reusable device drivers.  These global
variables should only defined by the BSP when using one of these device
drivers.

The BSP author probably should be aware of the @code{Configuration}
Table structure generated by @code{<rtems/confdefs.h>} during debug but
should not explicitly reference it in the source code.  There are helper
routines provided by RTEMS to access individual fields.

In older RTEMS versions, the BSP included a number of required global
variables.  We have made every attempt to eliminate these in the interest
of simplicity.

@section Board Initialization

This section describes the steps an application goes through from the
time the first BSP code is executed until the first application task
executes.  The following figure illustrates the program flow during
this sequence:

@ifset use-ascii
IMAGE NOT AVAILABLE IN ASCII VERSION
@end ifset

@ifset use-tex
@image{BSPInitFlowchart-49,6in,,Initialization Sequence,.png}
@c      @image{FILENAME[, WIDTH[, HEIGHT[, ALTTEXT[, EXTENSION]]]]}
@end ifset

@ifset use-html
@html
<center>
<IMG SRC="BSPInitFlowchart-49.png" WIDTH=800 ALT="Initialization Sequence">
</center>
@end html
@end ifset

The above figure illustrates the flow from assembly language start code
to the shared @code{bootcard.c} framework then through the C Library,
RTEMS, device driver initialization phases, and the context switch
to the first application task.  After this, the application executes
until it calls @code{exit}, @code{rtems_shutdown_executive}, or some
other normal termination initiating routine and a fatal system state is
reached.  The optional @code{bsp_fatal_extension} initial extension can perform
BSP specific system termination.

The routines invoked during this will be discussed and their location
in the RTEMS source tree pointed out as we discuss each.

@subsection Start Code - Assembly Language Initialization

The assembly language code in the directory @code{start} is the first part
of the application to execute.  It is responsible for initializing the
processor and board enough to execute the rest of the BSP.  This includes:

@itemize @bullet
@item initializing the stack
@item zeroing out the uninitialized data section @code{.bss}
@item disabling external interrupts
@item copy the initialized data from ROM to RAM
@end itemize

The general rule of thumb is that the start code in assembly should
do the minimum necessary to allow C code to execute to complete the
initialization sequence.

The initial assembly language start code completes its execution by
invoking the shared routine @code{boot_card()}.

The label (symbolic name) associated with the starting address of the
program is typically called @code{start}.  The start object file is the
first object file linked into the program image so it is ensured that
the start code is at offset 0 in the @code{.text} section.  It is the
responsibility of the linker script in conjunction with the compiler
specifications file to put the start code in the correct location in
the application image.

@subsection boot_card() - Boot the Card

The @code{boot_card()} is the first C code invoked.  This file is the
core component in the RTEMS BSP Initialization Framework and provides
the proper sequencing of initialization steps for the BSP, RTEMS and
device drivers. All BSPs use the same shared version of @code{boot_card()}
which is located in the following file:

@example
c/src/lib/libbsp/shared/bootcard.c
@end example

The @code{boot_card()} routine performs the following functions:

@itemize @bullet

@item It disables processor interrupts.

@item It sets the command line argument variables
for later use by the application.

@item It invokes the BSP specific routine @code{bsp_work_area_initialize()}
which is supposed to initialize the RTEMS Workspace and the C Program Heap.
Usually the default implementation in
@code{c/src/lib/libbsp/shared/bspgetworkarea.c} should be sufficient.  Custom
implementations can use @code{bsp_work_area_initialize_default()} or
@code{bsp_work_area_initialize_with_table()} available as inline functions from
@code{#include <bsp/bootcard.h>}.

@item It invokes the BSP specific routine @code{bsp_start()} which is
written in C and thus able to perform more advanced initialization.
Often MMU, bus and interrupt controller initialization occurs here.  Since the
RTEMS Workspace and the C Program Heap was already initialized by
@code{bsp_work_area_initialize()}, this routine may use @code{malloc()}, etc.

@item It invokes the RTEMS directive
@code{rtems_initialize_data_structures()} to initialize the RTEMS
executive to a state where objects can be created but tasking is not
enabled.

@item It invokes the BSP specific routine @code{bsp_libc_init()} to initialize
the C Library.  Usually the default implementation in
@code{c/src/lib/libbsp/shared/bsplibc.c} should be sufficient.

@item It invokes the RTEMS directive
@code{rtems_initialize_before_drivers()} to initialize the MPCI Server
thread in a multiprocessor configuration and execute API specific
extensions.

@item It invokes the BSP specific routine @code{bsp_predriver_hook}. For
most BSPs, the implementation of this routine does nothing.

@item It invokes the RTEMS directive
@code{rtems_initialize_device_drivers()} to initialize the statically
configured set of device drivers in the order they were specified in
the Configuration Table.

@item It invokes the BSP specific routine @code{bsp_postdriver_hook}. For
most BSPs, the implementation of this routine does nothing.  However, some
BSPs use this hook and perform some initialization which must be done at
this point in the initialization sequence.  This is the last opportunity
for the BSP to insert BSP specific code into the initialization sequence.

@item It invokes the RTEMS directive
@code{rtems_initialize_start_multitasking()}
which initiates multitasking and performs a context switch to the
first user application task and may enable interrupts as a side-effect of
that context switch.  The context switch saves the executing context.  The
application runs now.  The directive rtems_shutdown_executive() will return
to the saved context.  The exit() function will use this directive.

After a return to the saved context a fatal system state is reached.  The
fatal source is RTEMS_FATAL_SOURCE_EXIT with a fatal code set to the value
passed to rtems_shutdown_executive().

The enabling of interrupts during the first context switch is often the source
for fatal errors during BSP development because the BSP did not clear and/or
disable all interrupt sources and a spurious interrupt will occur.

When in the context of the first task but before its body has been
entered, any C++ Global Constructors will be invoked.

@end itemize

That's it.  We just went through the entire sequence. 

@subsection bsp_work_area_initialize() - BSP Specific Work Area Initialization

This is the first BSP specific C routine to execute during system
initialization.  It must initialize the support for allocating memory from the
C Program Heap and RTEMS Workspace commonly referred to as the work areas.
Many BSPs place the work areas at the end of RAM although this is certainly not
a requirement.  Usually the default implementation in
@file{c/src/lib/libbsp/shared/bspgetworkarea.c} should be sufficient.  Custom
implementations can use @code{bsp_work_area_initialize_default()} or
@code{bsp_work_area_initialize_with_table()} available as inline functions from
@code{#include <bsp/bootcard.h>}.

@subsection bsp_start() - BSP Specific Initialization

This is the second BSP specific C routine to execute during system
initialization.  It is called right after @code{bsp_work_area_initialize()}.
The @code{bsp_start()} routine often performs required fundamental hardware
initialization such as setting bus controller registers that do not have a
direct impact on whether or not C code can execute.  The interrupt controllers
are usually initialized here.  The source code for this routine is usually
found in the file @file{c/src/lib/libbsp/$@{CPU@}/$@{BSP@}/startup/bspstart.c}.
It is not allowed to create any operating system objects, e.g. RTEMS
semaphores.

After completing execution, this routine returns to the @code{boot_card()}
routine.  In case of errors, the initialization should be terminated via
@code{bsp_fatal()}.

@subsection bsp_predriver_hook() - BSP Specific Predriver Hook

The @code{bsp_predriver_hook()} method is the BSP specific routine that is
invoked immediately before the the device drivers are initialized. RTEMS
initialization is complete but interrupts and tasking are disabled.

The BSP may use the shared version of this routine which is empty.
Most BSPs do not provide a specific implementation of this callback.

@subsection Device Driver Initialization

At this point in the initialization sequence, the initialization 
routines for all of the device drivers specified in the Device
Driver Table are invoked.  The initialization routines are invoked
in the order they appear in the Device Driver Table.

The Driver Address Table is part of the RTEMS Configuration Table. It
defines device drivers entry points (initialization, open, close, read,
write, and control). For more information about this table, please
refer to the @b{Configuring a System} chapter in the
@b{RTEMS Application C User's Guide}.

The RTEMS initialization procedure calls the initialization function for
every driver defined in the RTEMS Configuration Table (this allows
one to include only the drivers needed by the application). 

All these primitives have a major and a minor number as arguments: 

@itemize @bullet

@item the major number refers to the driver type,

@item the minor number is used to control two peripherals with the same
driver (for instance, we define only one major number for the serial
driver, but two minor numbers for channel A and B if there are two
channels in the UART). 

@end itemize

@subsection RTEMS Postdriver Callback

The @code{bsp_postdriver_hook()} BSP specific routine is invoked
immediately after the the device drivers and MPCI are initialized.
Interrupts and tasking are disabled.

Most BSPs use the shared implementation of this routine which is responsible for opening the device @code{/dev/console} for standard input, output and error if the application has configured the Console Device Driver.  This file is located at:

@example
c/src/lib/libbsp/shared/bsppost.c
@end example

@section The Interrupt Vector Table

The Interrupt Vector Table is called different things on different
processor families but the basic functionality is the same.  Each
entry in the Table corresponds to the handler routine for a particular
interrupt source.  When an interrupt from that source occurs, the 
specified handler routine is invoked.  Some context information is
saved by the processor automatically when this happens.  RTEMS saves
enough context information so that an interrupt service routine
can be implemented in a high level language.

On some processors, the Interrupt Vector Table is at a fixed address.  If
this address is in RAM, then usually the BSP only has to initialize
it to contain pointers to default handlers.  If the table is in ROM,
then the application developer will have to take special steps to
fill in the table.

If the base address of the Interrupt Vector Table can be dynamically 
changed to an arbitrary address, then the RTEMS port to that processor
family will usually allocate its own table and install it.  For example,
on some members of the Motorola MC68xxx family, the Vector Base Register
(@code{vbr}) contains this base address.  

@subsection Interrupt Vector Table on the gen68340 BSP

The gen68340 BSP provides a default Interrupt Vector Table in the
file @code{$BSP_ROOT/start340/start340.s}.  After the @code{entry}
label is the definition of space reserved for the table of
interrupts vectors.  This space is assigned the symbolic name
of @code{__uhoh} in the @code{gen68340} BSP.

At @code{__uhoh} label is the default interrupt handler routine. This
routine is only called when an unexpected interrupts is raised.  One can
add their own routine there (in that case there's a call to a routine -
$BSP_ROOT/startup/dumpanic.c - that prints which address caused the
interrupt and the contents of the registers, stack, etc.), but this should
not return. 

@section Chip Select Initialization

When the microprocessor accesses a memory area, address decoding is
handled by an address decoder, so that the microprocessor knows which
memory chip(s) to access.   The following figure illustrates this:

@example
@group
                     +-------------------+
         ------------|                   |
         ------------|                   |------------
         ------------|      Address      |------------
         ------------|      Decoder      |------------
         ------------|                   |------------
         ------------|                   |
                     +-------------------+
           CPU Bus                           Chip Select
@end group
@end example


The Chip Select registers must be programmed such that they match
the @code{linkcmds} settings. In the gen68340 BSP, ROM and RAM
addresses can be found in both the @code{linkcmds} and initialization
code, but this is not a great way to do this.  It is better to
define addresses in the linker script.

@section Integrated Processor Registers Initialization

The CPUs used in many embedded systems are highly complex devices
with multiple peripherals on the CPU itself.  For these devices,
there are always some specific integrated processor registers
that must be initialized.  Refer to the processors' manuals for
details on these registers and be VERY careful programming them.

@section Data Section Recopy

The next initialization part can be found in
@code{$BSP340_ROOT/start340/init68340.c}. First the Interrupt
Vector Table is copied into RAM, then the data section recopy is initiated
(_CopyDataClearBSSAndStart in @code{$BSP340_ROOT/start340/startfor340only.s}). 

This code performs the following actions:

@itemize @bullet

@item copies the .data section from ROM to its location reserved in RAM
(see @ref{Linker Script Initialized Data} for more details about this copy),

@item clear @code{.bss} section (all the non-initialized
data will take value 0). 

@end itemize

@section The RTEMS Configuration Table

The RTEMS configuration table contains the maximum number of objects RTEMS
can handle during the application (e.g. maximum number of tasks,
semaphores, etc.). It's used to allocate the size for the RTEMS inner data
structures. 

The RTEMS configuration table is application dependent, which means that
one has to provide one per application. It is usually defined by defining
macros and including the header file @code{<rtems/confdefs.h>}.  In simple
applications such as the tests provided with RTEMS, it is commonly found
in the main module of the application.  For more complex applications,
it may be in a file by itself.

The header file @code{<rtems/confdefs.h>} defines a constant table
named @code{Configuration}.  With RTEMS 4.8 and older, it was accepted
practice for the BSP to copy this table into a modifiable copy named
@code{BSP_Configuration}.  This copy of the table was modified to define
the base address of the RTEMS Executive Workspace as well as to reflect
any BSP and device driver requirements not automatically handled by the
application.  In 4.9 and newer, we have eliminated the BSP copies of the
configuration tables and are making efforts to make the configuration
information generated by @code{<rtems/confdefs.h>} constant and read only.

For more information on the RTEMS Configuration Table, refer to the
@b{RTEMS Application C User's Guide}.

