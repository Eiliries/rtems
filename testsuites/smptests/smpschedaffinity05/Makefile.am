rtems_tests_PROGRAMS = smpschedaffinity05
smpschedaffinity05_SOURCES = init.c

dist_rtems_tests_DATA = smpschedaffinity05.scn smpschedaffinity05.doc

include $(RTEMS_ROOT)/make/custom/@RTEMS_BSP@.cfg
include $(top_srcdir)/../automake/compile.am
include $(top_srcdir)/../automake/leaf.am

AM_CPPFLAGS += -I$(top_srcdir)/../support/include

LINK_OBJS = $(smpschedaffinity05_OBJECTS)
LINK_LIBS = $(smpschedaffinity05_LDLIBS)

smpschedaffinity05$(EXEEXT): $(smpschedaffinity05_OBJECTS) $(smpschedaffinity05_DEPENDENCIES)
	@rm -f smpschedaffinity05$(EXEEXT)
	$(make-exe)

include $(top_srcdir)/../automake/local.am
