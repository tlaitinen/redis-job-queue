{-# LANGUAGE OverloadedStrings #-}
import RedisJobQueue
import Control.Concurrent
import Data.Aeson 
import Data.Text (Text)

main :: IO ()
main = do
    forkIO $ withJobQueue "q" $ \jq -> do
        _ <- pushJson jq 2 $ object [ "message" .= ("two" :: Text) ]
        _ <- pushJson jq 3 $ object [ "message" .= ("three" :: Text)]
        _ <- pushJson jq 1 $ object [ "message" .= ("one" :: Text) ]
        return ()
    threadDelay 500000
    withJobQueue "q" f
    where
        f jq = do
            r <- popJson jq
            case r of
                Right (Just j) -> do
                    print j
                    f jq
                Right Nothing -> return ()
                Left r -> print r


        

        
    

