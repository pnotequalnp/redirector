{-# LANGUAGE OverloadedStrings #-}

module Main where

import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as BS
import Data.Maybe (fromMaybe, listToMaybe)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import qualified Data.Text.IO as T
import Database.PostgreSQL.Simple (Connection, Only(..), connectPostgreSQL, query)
import Network.HTTP.Types (found302)
import Network.Wai (Application, Response, pathInfo, responseLBS)
import Network.Wai.Handler.Warp (run)
import System.Environment (lookupEnv)
import System.IO (stderr)
import Text.Read (readMaybe)

main :: IO ()
main = do
  port'     <- lookupEnv "PORT"
  fallback' <- lookupEnv "FALLBACK"
  conn      <- connectPostgreSQL ""
  let port     = fromMaybe 80 $ port' >>= readMaybe
      fallback = maybe "/" BS.pack fallback'
  T.hPutStrLn stderr $
    "Running on port " <> (T.pack . show) port <> " with fallback '" <> T.decodeUtf8 fallback <> "'"
  run port $ app conn fallback

app :: Connection -> ByteString -> Application
app conn fallback req respond = do
  let path = T.intercalate "/" . pathInfo $ req
  res <- redirect conn fallback path
  respond res

redirect :: Connection -> ByteString -> Text -> IO Response
redirect conn fallback short = do
  l <- queryLink conn short
  let link = maybe fallback T.encodeUtf8 l
  pure $ responseLBS found302 [("Location", link)] ""

queryLink :: Connection -> Text -> IO (Maybe Text)
queryLink conn short = do
  res <- query conn
    "select original from links where short = ? and enabled = true" (Only short) :: IO [Only Text]
  pure $ fromOnly <$> listToMaybe res
