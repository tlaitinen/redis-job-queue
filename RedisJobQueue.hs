{-# LANGUAGE OverloadedStrings #-}

module RedisJobQueue (
    withJobQueue,
    withJobQueue',
    JobQueue,
    push,
    pop,
    pushJson,
    popJson,
    QueueName,
    Job,
    Priority
) where

import Database.Redis
import Data.ByteString
import qualified Data.Aeson as A
import qualified Data.ByteString.Lazy as LBS
import Data.ByteString.Char8 as BS8


type QueueName = ByteString
type Job       = ByteString
type Priority  = Double

data JobQueue = JobQueue QueueName Connection

withJobQueue :: QueueName -> (JobQueue -> IO ()) -> IO ()
withJobQueue = withJobQueue' defaultConnectInfo

withJobQueue' :: ConnectInfo -> QueueName -> (JobQueue -> IO ()) -> IO ()
withJobQueue' connInfo qn f = do
    conn <- connect connInfo
    f $ JobQueue qn conn

push :: JobQueue -> Priority -> Job -> IO (Either Reply Integer)
push (JobQueue qn conn) p j = runRedis conn $ zadd qn [(p,j)]
 
pop :: JobQueue -> IO (Either Reply (Maybe Job))
pop (JobQueue qn conn) = runRedis conn $ do
    _ <- watch [qn]
    js <- zrange qn 0 0 
    case js of  
        Right (j:_) -> do
            r <- multiExec $ zrem qn [j]
            case r of
                TxSuccess _ -> return $ Right (Just j)
                TxAborted -> return $ Left $ Error "aborted"
                TxError err -> return $ Left $ Error $ BS8.pack err
        Right [] -> do
            _ <- unwatch
            return $ Right Nothing
        Left e -> return $ Left e
        
pushJson :: A.ToJSON a => JobQueue -> Priority -> a -> IO (Either Reply Integer)
pushJson jq p j = push jq p $ LBS.toStrict $ A.encode j

popJson :: A.FromJSON a => JobQueue -> IO (Either String (Maybe a))
popJson jq = do
    mj <- pop jq
    case mj of
        Right (Just j) -> return $ A.eitherDecode $ LBS.fromStrict j
        Right Nothing -> return $ Right Nothing
        Left l -> return $ Left (show l)
    
    
    
     

