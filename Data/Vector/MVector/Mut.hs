{-# LANGUAGE Rank2Types, ScopedTypeVariables #-}

#include "phases.h"

module Data.Vector.MVector.Mut (
  Mut(..), run, unstream, update, reverse, map
) where

import qualified Data.Vector.MVector as MVector
import           Data.Vector.MVector ( MVector )

import           Data.Vector.Stream ( Stream )
import qualified Data.Vector.Stream as Stream

import           Data.Vector.MStream ( MStream )
import qualified Data.Vector.MStream as MStream

import Control.Monad  ( liftM )
import Prelude hiding ( reverse, map )

data Mut a = Mut (forall m mv. MVector mv m a => m (mv a))

run :: MVector mv m a => Mut a -> m (mv a)
{-# INLINE run #-}
run (Mut p) = p

trans :: Mut a -> (forall m mv. MVector mv m a => mv a -> m ()) -> Mut a
{-# INLINE trans #-}
trans (Mut p) q = Mut (do { v <- p; q v; return v })

unstream :: Stream a -> Mut a
{-# INLINE_STREAM unstream #-}
unstream s = Mut (MVector.unstream s)

inplace :: (forall m. Monad m => MStream m a -> MStream m a) -> Mut a -> Mut a
{-# INLINE_STREAM inplace #-}
inplace f (Mut p) = Mut (
  do
    v <- p
    MVector.munstream v (f (MVector.mstream v)))

{-# RULES

"inplace/inplace [Mut]"
  forall (f :: forall m. Monad m => MStream m a -> MStream m a)
         (g :: forall m. Monad m => MStream m a -> MStream m a) p .
  inplace f (inplace g p) = inplace (f . g) p

 #-}

update :: Mut a -> Stream (Int, a) -> Mut a
{-# INLINE_STREAM update #-}
update m s = trans m (\v -> MVector.update v s)

reverse :: Mut a -> Mut a
{-# INLINE_STREAM reverse #-}
reverse m = trans m (MVector.reverse)

map :: (a -> a) -> Mut a -> Mut a
{-# INLINE map #-}
map f = inplace (MStream.map f)

filter :: (a -> Bool) -> Mut a -> Mut a
{-# INLINE filter #-}
filter f = inplace (MStream.filter f)

