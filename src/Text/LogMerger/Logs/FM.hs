{-# LANGUAGE DeriveDataTypeable, UnicodeSyntax, OverloadedStrings,
             FlexibleContexts, RankNTypes #-}
module Text.LogMerger.Logs.FM
       (
         logFormat
       ) where

import Pipes.Dissect
import Control.Applicative
import Control.Monad
import Data.Attoparsec.ByteString.Char8
import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy.Internal as B
import Text.LogMerger.Types
import Text.LogMerger.Logs.Types
import Text.LogMerger.Logs.Util
import Prelude hiding (takeWhile)

logFormat = LogFormat {
    _dissector = evalStateT fmaDissector
  , _nameRegex = mkRegex "fm_(event|alarm)\\.[0-9]+$"
  , _formatName = "sgsn-mme-fm"
  , _formatDescription = "Log of Fault Management events and alarms of an SGSN-MME node"
  , _timeAs = AsLocalTime
  }

fmaDissector ∷ (Monad m)
             ⇒ Dissector SGSNBasicEntry m (Either String ())
fmaDissector = tillEnd $ do
  b ← count 4 $ takeTill (==';') <* ";"
  skipWhile isSpace
  day ← (yymmdd <* skipWhile isSpace) <?> "Day"
  time ← (hhmmss <* ";") <?> "Time"
  (rest, _) ← (match $ (takeTill (=='\n') <* "\n")) <?> "rest"
  return BasicLogEntry {
      _basic_origin = []
    , _basic_date = UTCTime {
          utctDay     = day
        , utctDayTime = time
        }
    , _basic_text = B.intercalate "; " $ b ++ [rest]
    }
