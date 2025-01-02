module Main (main) where

import Control.Monad
import Control.Monad.Fix
import Control.Monad.IO.Class
import Data.Functor
import Reflex
import Reflex.Host.Headless

main :: IO ()
main = runHeadlessApp app

app ::
  forall t m.
  ( MonadFix m
  , MonadHold t m
  , PerformEvent t m
  , MonadIO (Performable m)
  , PostBuild t m
  , TriggerEvent t m
  , MonadIO m
  ) =>
  m (Event t ())
app = do
  eTick <- tickLossyFromPostBuildTime 0.1

  -- usage of `mergeMapIncremental` cause the casuality loop
  e1 <- mergeMapIncremental <$> holdIncremental @_ @_ @(PatchMap Int (Event t ())) mempty never
  d1 <- holdDyn mempty e1

  dGate <- toggle False (eTick $> True)

  e2 <- mergeMapIncremental <$> holdIncremental @_ @_ @(PatchMap Int (Event t ())) mempty (eTick $> mempty)
  d2 <- holdDyn mempty e2

  let d3 = do
        d1
        gate <- dGate
        when gate (d2 $> ()) -- d2 is optionally evaluated by dGate
  performEvent_ $ updated d3 $> pure () -- subscribe `updated d3`
  pure never
