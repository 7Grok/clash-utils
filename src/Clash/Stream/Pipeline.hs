module Clash.Stream.Pipeline (
        pipeline,
        skidBuffer
    ) where

import Clash.Prelude

pipeline
    :: forall dom a
    .  (HiddenClockResetEnable dom, NFDataX a)
    => Signal dom Bool
    -> Signal dom a
    -> Signal dom Bool
    -> (Signal dom Bool, Signal dom a, Signal dom Bool)
pipeline vldIn datIn readyIn = (vldOut, datOut, readyOut)
    where

    readyOut :: Signal dom Bool
    readyOut =  readyIn .||. fmap not vldOut

    vldOut :: Signal dom Bool
    vldOut =  register False $ vldIn .||. (vldOut .&&. fmap not readyIn)

    datOut :: Signal dom a
    datOut =  regEn (errorX "initial stream pipeline value") readyOut datIn

skidBuffer
    :: forall dom a
    .  (HiddenClockResetEnable dom, NFDataX a)
    => Signal dom Bool
    -> Signal dom a
    -> Signal dom Bool
    -> (Signal dom Bool, Signal dom a, Signal dom Bool)
skidBuffer vldIn datIn readyIn = (vldOut, datOut, readyOut)
    where
    buffered :: Signal dom Bool
    buffered =  register False $ (vldIn .||. buffered) .&&. fmap not readyIn

    readyOut :: Signal dom Bool
    readyOut =  fmap not buffered

    vldOut :: Signal dom Bool
    vldOut =  buffered .||. vldIn

    datSaved :: Signal dom a
    datSaved =  regEn (errorX "initial skid buffer pipeline value") readyOut datIn

    datOut :: Signal dom a
    datOut =  mux buffered datSaved datIn
