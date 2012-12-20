--
-- HTTP client for use with io-streams
--
-- Copyright © 2012 Operational Dynamics Consulting, Pty Ltd
--
-- The code in this file, and the program it is a part of, is made
-- available to you by its authors as open source software: you can
-- redistribute it and/or modify it under a BSD licence.
--

{-# LANGUAGE OverloadedStrings #-}

import Network.Http.Client
import Control.Exception (bracket)

--
-- Otherwise redundent imports, but useful for testing in GHCi.
--

import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as S
import System.IO.Streams (InputStream,OutputStream)
import qualified System.IO.Streams as Streams


main :: IO ()
main = do
    putStrLn "basic:"
    basic
    putStrLn "----"
    putStrLn "resource:"
    b' <- resource
    S.putStrLn b'
    putStrLn "----"
    putStrLn "express:"
    express

{-
    Explore with a simple HTTP request against localhost (where we
    already have an Apache server running; that will need to be more
    sophisticated once we start writing real tests.
-}

basic :: IO ()
basic = do
    c <- openConnection "localhost" 8000
    putStrLn $ show c
    
    q <- buildRequest c $ do
        http GET "/time"
        setAccept "text/plain"
    putStrLn $ show q
    
    p <- sendRequest c q emptyBody
    putStrLn $ show p
    
    b <- receiveResponse c
    
    x <- Streams.read b
    S.putStrLn $ maybe "" id x

    closeConnection c

{-
    One of the deisgn features of io-streams is their use of the
    standard IO monad exception handling facilities. This example
    doesn't do much yet, but shows the basic usage pattern. Presumably
    the resulant ByteString (in this case) bubbling out of doStuff would
    be returned to the calling program to then be put to some use.
-}

resource :: IO ByteString
resource = bracket
    (openConnection "www.httpbin.org" 80)
    (closeConnection)
    (doStuff)


-- Now actually use the supplied Connection object to further
-- exercise the API. We'll do a PUT this time.
    
doStuff :: Connection -> IO ByteString
doStuff c = do
    q <- buildRequest c $ do
        http PUT "/item/56"
        setAccept "*/*"
        setContentType "text/plain"
    
    p <- sendRequest c q (\o ->
        Streams.write (Just "Hello World\n") o)
    
    b <- receiveResponse c

   
    x <- Streams.read b

    return $ maybe "" id x



{-
    Experiment with a convenience API. This is very much in flux,
    with the open question being what type to return; since there's
    no Connection object here (its use being wrapped) we possibly want
    to run the entire Stream into memory. Or, we could a handler?
-}

express :: IO ()
express = do
    p <- get "http://localhost/item/56"
    
    putStrLn $ show (p)

