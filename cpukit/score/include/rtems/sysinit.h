/*
 * Copyright (c) 2015 embedded brains GmbH.  All rights reserved.
 *
 *  embedded brains GmbH
 *  Dornierstr. 4
 *  82178 Puchheim
 *  Germany
 *  <rtems@embedded-brains.de>
 *
 * The license and distribution terms for this file may be
 * found in the file LICENSE in this distribution or at
 * http://www.rtems.org/license/LICENSE.
 */

#ifndef _RTEMS_SYSINIT_H
#define _RTEMS_SYSINIT_H

#include <rtems/linkersets.h>

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

/*
 * The value of each module define must consist of exactly six hexadecimal
 * digits without a 0x-prefix.  A 0x-prefix is concatenated with the module and
 * order values to form a proper integer literal.
 */
#define RTEMS_SYSINIT_BSP_WORK_AREAS             000100
#define RTEMS_SYSINIT_BSP_START                  000200
#define RTEMS_SYSINIT_DATA_STRUCTURES            000300
#define RTEMS_SYSINIT_BSP_LIBC                   000400
#define RTEMS_SYSINIT_BEFORE_DRIVERS             000500
#define RTEMS_SYSINIT_BSP_PRE_DRIVERS            000600
#define RTEMS_SYSINIT_DEVICE_DRIVERS             000700
#define RTEMS_SYSINIT_BSP_POST_DRIVERS           000800

/*
 * The value of each order define must consist of exactly two hexadecimal
 * digits without a 0x-prefix.  A 0x-prefix is concatenated with the module and
 * order values to form a proper integer literal.
 */
#define RTEMS_SYSINIT_ORDER_FIRST  00
#define RTEMS_SYSINIT_ORDER_MIDDLE 08
#define RTEMS_SYSINIT_ORDER_LAST   0f

typedef void ( *rtems_sysinit_handler )( void );

typedef struct {
  rtems_sysinit_handler handler;
} rtems_sysinit_item;

/* The enum helps to detect typos in the module and order parameters */
#define _RTEMS_SYSINIT_INDEX_ITEM( handler, index ) \
  enum { _Sysinit_##handler = index }; \
  RTEMS_LINKER_ROSET_ITEM_ORDERED( \
    _Sysinit, \
    rtems_sysinit_item, \
    handler, \
    index \
  ) = { handler }

/* Create index from module and order */
#define _RTEMS_SYSINIT_ITEM( handler, module, order ) \
  _RTEMS_SYSINIT_INDEX_ITEM( handler, 0x##module##order )

/* Perform parameter expansion */
#define RTEMS_SYSINIT_ITEM( handler, module, order ) \
  _RTEMS_SYSINIT_ITEM( handler, module, order )

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* _RTEMS_SYSINIT_H */
