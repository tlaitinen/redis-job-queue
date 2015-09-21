# redis-job-queue
Simple Redis-backed job priority queue in Haskell modeled after [http://product.reverb.com/2015/01/31/a-simple-priority-queue-with-redis-in-ruby/](http://product.reverb.com/2015/01/31/a-simple-priority-queue-with-redis-in-ruby/).

# Example
```haskell
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
                    print (j :: Value)
                    f jq
                Right Nothing -> return ()
                Left r -> print r

```

Outputs: 
```
Object (fromList [("tag",String "C"),("contents",Number 1.0)])
Object (fromList [("tag",String "A"),("contents",Number 2.0)])
Object (fromList [("tag",String "B"),("contents",String "three")])
```
