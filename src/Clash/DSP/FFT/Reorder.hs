module Clash.DSP.FFT.Reorder (
    bitReversalReorder
    ) where

import Clash.Prelude
import Clash.Counter
import Clash.Misc

bitReversalReorder
    :: forall dom n a
    .  HiddenClockResetEnable dom
    => NFDataX a
    => Default a
    => SNat n
    -> Signal dom Bool
    -> Signal dom a
    -> Signal dom a
bitReversalReorder SNat en dat = ramOut
    where

    counter :: Signal dom (BitVector (n + 1))
    counter =  count 0 en

    (stage' :: Signal dom (BitVector 1), address' :: Signal dom (BitVector n)) 
        = unbundle $ split <$> counter

    stage :: Signal dom Bool
    stage = unpack <$> stage'

    address :: Signal dom (Unsigned n)
    address = unpack <$> address'

    addressReversed :: Signal dom (Unsigned n)
    addressReversed = unpack . revBV <$> address'

    addressFinal = mux stage address addressReversed

    ramOut = blockRamPow2 (repeat def :: Vec (2 ^ n) a) addressFinal
        $ mux en (Just <$> bundle (addressFinal, dat)) (pure Nothing)

