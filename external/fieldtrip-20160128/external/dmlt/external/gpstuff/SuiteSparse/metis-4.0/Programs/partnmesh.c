/*
 * Copyright 1997, Regents of the University of Minnesota
 *
 * partnmesh.c
 *
 * This file reads in the element node connectivity array of a mesh and 
 * partitions both the elements and the nodes using KMETIS on the dual graph.
 *
 * Started 9/29/97
 * George
 *
 * $Id: partnmesh.c 8776 2013-11-14 09:04:48Z roboos $
 *
 */

#include <metis.h>



/*************************************************************************
* Let the game begin
**************************************************************************/
main(int argc, char *argv[])
{
  int i, j, ne, nn, etype, numflag=0, nparts, edgecut;
  idxtype *elmnts, *epart, *npart;
  timer IOTmr, DUALTmr;
  char etypestr[4][5] = {"TRI", "TET", "HEX", "QUAD"};
  GraphType graph;

  if (argc != 3) {
    printf("Usage: %s <meshfile> <nparts>\n",argv[0]);
    exit(0);
  }

  nparts = atoi(argv[2]);
  if (nparts < 2) {
    printf("nparts must be greater than one.\n");
    exit(0);
  }
   
  cleartimer(IOTmr);
  cleartimer(DUALTmr);

  starttimer(IOTmr);
  elmnts = ReadMesh(argv[1], &ne, &nn, &etype);
  stoptimer(IOTmr);

  epart = idxmalloc(ne, "main: epart");
  npart = idxmalloc(nn, "main: npart");

  printf("**********************************************************************\n");
  printf("%s", METISTITLE);
  printf("Mesh Information ----------------------------------------------------\n");
  printf("  Name: %s, #Elements: %d, #Nodes: %d, Etype: %s\n\n", argv[1], ne, nn, etypestr[etype-1]);
  printf("Partitioning Nodal Graph... -----------------------------------------\n");


  starttimer(DUALTmr);
  METIS_PartMeshNodal(&ne, &nn, elmnts, &etype, &numflag, &nparts, &edgecut, epart, npart);
  stoptimer(DUALTmr);

  printf("  %d-way Edge-Cut: %7d, Balance: %5.2f\n", nparts, edgecut, ComputeElementBalance(ne, nparts, epart));

  starttimer(IOTmr);
  WriteMeshPartition(argv[1], nparts, ne, epart, nn, npart);
  stoptimer(IOTmr);


  printf("\nTiming Information --------------------------------------------------\n");
  printf("  I/O:          \t\t %7.3f\n", gettimer(IOTmr));
  printf("  Partitioning: \t\t %7.3f\n", gettimer(DUALTmr));
  printf("**********************************************************************\n");

/*
  graph.nvtxs = ne;
  graph.xadj = idxmalloc(ne+1, "xadj");
  graph.vwgt = idxsmalloc(ne, 1, "vwgt");
  graph.adjncy = idxmalloc(10*ne, "adjncy");
  graph.adjwgt = idxsmalloc(10*ne, 1, "adjncy");

  METIS_MeshToDual(&ne, &nn, elmnts, &etype, &numflag, graph.xadj, graph.adjncy);

  ComputePartitionInfo(&graph, nparts, epart);

  GKfree(&graph.xadj, &graph.adjncy, &graph.vwgt, &graph.adjwgt, LTERM);
*/

  GKfree(&elmnts, &epart, &npart, LTERM);

}


