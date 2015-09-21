{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
import RedisJobQueue
import Control.Concurrent
import Data.Aeson 
import Data.Aeson.TH
import Data.Text (Text)

data Task = A Int | B Text | C Double
$(deriveJSON defaultOptions ''Task)

main :: IO ()
main = do
    forkIO $ withJobQueue "q" $ \jq -> do
        _ <- pushJson jq 2 $ A 2
        _ <- pushJson jq 3 $ B "three"
        _ <- pushJson jq 1 $ C 1.0
        return ()
    threadDelay 500000
    withJobQueue "q" f
    where
        f jq = do
            r <- popJson jq
            case r of
                Right (Just j) -> do
                    print ( j :: Value)
                    f jq
                Right Nothing -> return ()
                Left r -> print r


        

        
    

