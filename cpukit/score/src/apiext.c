/**
 * @file
 *
 * @brief Holding for API Extension Functions
 *
 * @ingroup ScoreAPIExtension
 */

/*
 *  COPYRIGHT (c) 1989-1999.
 *  On-Line Applications Research Corporation (OAR).
 *
 *  The license and distribution terms for this file may be
 *  found in the file LICENSE in this distribution or at
 *  http://www.rtems.org/license/LICENSE.
 */

#if HAVE_CONFIG_H
#include "config.h"
#endif

#include <rtems/score/apiext.h>

static CHAIN_DEFINE_EMPTY( _API_extensions_List );

void _API_extensions_Add(
  API_extensions_Control *the_extension
)
{
  _Chain_Append( &_API_extensions_List, &the_extension->Node );
}

void _API_extensions_Run_postdriver( void )
{
  Chain_Node             *the_node;
  API_extensions_Control *the_extension;

  for ( the_node = _Chain_First( &_API_extensions_List );
        !_Chain_Is_tail( &_API_extensions_List, the_node ) ;
        the_node = the_node->next ) {

    the_extension = (API_extensions_Control *) the_node;

    /*
     *  Currently all APIs configure this hook so it is always non-NULL.
     */
    (*the_extension->postdriver_hook)();
  }
}
