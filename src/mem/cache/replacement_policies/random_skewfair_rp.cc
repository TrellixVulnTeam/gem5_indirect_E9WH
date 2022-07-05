/**
 * Copyright (c) 2018 Inria
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met: redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer;
 * redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution;
 * neither the name of the copyright holders nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Authors: Daniel Carvalho
 */

#include "mem/cache/replacement_policies/random_skewfair_rp.hh"
#include "debug/Cache.hh"


#include <cassert>
#include <memory>

#include "base/random.hh"
#include "params/RandomSkewfairRP.hh"

namespace gem5{

GEM5_DEPRECATED_NAMESPACE(ReplacementPolicy, replacement_policy);
namespace replacement_policy
{
RandomSkewfairRP::RandomSkewfairRP(const Params &p)
  : Base(p),
    numSkews(p.numSkews),
    assoc(p.assoc),
    randomizedIndirectIndexing(p.randomizedIndirectIndexing),
    randomizedIndexing(p.randomizedIndexing),
    TDR(p.TDR)
{
  //DPRINTFN("For Random Skew-Fair replacement policy: numSkews:%d, assoc:%d. \n",numSkews,assoc);
}

void
RandomSkewfairRP::invalidate(const std::shared_ptr<ReplacementData>& replacement_data)
  
{

  // Unprioritize replacement data victimization
  std::static_pointer_cast<RandomReplData>(
                                           replacement_data)->valid = false;
}

void
RandomSkewfairRP::touch(const std::shared_ptr<ReplacementData>& replacement_data) const
{
}

void
RandomSkewfairRP::reset(const std::shared_ptr<ReplacementData>& replacement_data) const
{
  // Unprioritize replacement data victimization
  std::static_pointer_cast<RandomReplData>(
                                           replacement_data)->valid = true;
}

ReplaceableEntry*
RandomSkewfairRP::getVictim(const ReplacementCandidates& candidates) const
{
  // There must be at least one replacement candidate
  assert(candidates.size() > 0);

  // Choose one candidate at random
  ReplaceableEntry* victim = candidates[random_mt.random<unsigned>(0,
                                                                   candidates.size() - 1)];

  //Ensure number of victim candidates == assoc
  if(randomizedIndexing)
    assert(candidates.size() == assoc);
  else if(randomizedIndirectIndexing)
    assert(candidates.size() == (assoc + (TDR-1)*assoc/TDR));

  // int k=0;
  // for (const auto& candidate : candidates) {
  //   if (!std::static_pointer_cast<RandomReplData>
  //       (candidate->replacementData)->valid) {
  //     int skew_id = candidate->getWay() / (assoc/numSkews);
  //     DPRINTFN("Invalid Candidate-%d in Skew-%d\n",k,skew_id);
  //   }
  //   k++;
  // }

  // Visit all skews to see how many invalid entries present in each skew.
  int invalid_per_skew[numSkews];
  for (int i=0; i<numSkews; i++){
    invalid_per_skew[i] = 0;
  }

    
  for (const auto& candidate : candidates) {
    if (!std::static_pointer_cast<RandomReplData>
        (candidate->replacementData)->valid) {
      if(randomizedIndirectIndexing == true){
        //printf("random skew replacementt .cc getting skew id\n");
        int skew_id;
        if(candidate->getWay()<(assoc/TDR))
          skew_id = candidate->getWay() / ((assoc + (TDR-1)*assoc/TDR)/numSkews);
        else
          skew_id = (candidate->getWay()-(assoc/TDR))/4 + 2;
        invalid_per_skew[skew_id]++;
      } 
      else
      { 
        int skew_id = candidate->getWay() / (assoc/numSkews);
        invalid_per_skew[skew_id]++;
      }
    }
  }
  if(randomizedIndirectIndexing == true)
  {
    if(numSkews != 4)
      panic("Number of Skews not as expected");
    if((invalid_per_skew[0]>0) | (invalid_per_skew[1]>0))
    {
      invalid_per_skew[2] = 0;
      invalid_per_skew[3] = 0;
    }
  }
  //DPRINTFN("Invalid Skews Are: \n");
  // for(int i=0;i<numSkews;i++){
  //   //DPRINTFN("Skew-%d: %d\n",i,invalid_per_skew[i]);
  // }
  
  // Find maximum invalid skew
  int max_invalid_skew = 0;  
  for(int i=0;i<numSkews;i++){
    if(invalid_per_skew[i] > invalid_per_skew[max_invalid_skew])
      max_invalid_skew = i;
  }

  //DPRINTFN("Max-Invalid is Skew-%d: %d\n",max_invalid_skew,invalid_per_skew[max_invalid_skew]);
  
  
  // Victimize a invalid line from the max-invalid-skew, if such a invalid line exists
  // k=0;
  if(invalid_per_skew[max_invalid_skew]){
    for (const auto& candidate : candidates) {
      int skew_id;
      if(randomizedIndirectIndexing == true){
        //printf("random skew replacementt .cc getting skew id\n");
        
        if(candidate->getWay()<(assoc/TDR))
          skew_id = candidate->getWay() / ((assoc + (TDR-1)*assoc/TDR)/numSkews);
        else
          skew_id = (candidate->getWay()-(assoc/TDR))/4 + 2;
        
      } 
      else
      { 
         skew_id = candidate->getWay() / (assoc/numSkews);
        
      }
    
      if ((!std::static_pointer_cast<RandomReplData>(candidate->replacementData)->valid) &&
          (skew_id == max_invalid_skew))
        {
          victim = candidate;
          //DPRINTFN("Final Victim Candidate-%d in Skew-%d\n",k,skew_id);
          break;
        }
      // k++;
    }
  }
  return victim;
}

std::shared_ptr<ReplacementData>
RandomSkewfairRP::instantiateEntry()
{
  return std::shared_ptr<ReplacementData>(new RandomReplData());
}
}



}