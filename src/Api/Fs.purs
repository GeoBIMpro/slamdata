-- | This module will be reworked after `affjax` is ready.
module Api.Fs (
  makeNotebook,
  deleteItem,
  makeFile,
  listing
  ) where

import Control.Monad.Eff
import Control.Monad.Eff.Exception (error)
import DOM (DOM())
import Data.Maybe
import Data.Either
import Control.Monad.Error.Class
import Data.Foreign
import Data.Foreign.Class

import qualified Control.Monad.Aff as Aff
import qualified Data.Array as Arr
import qualified Data.String as Str
import qualified Data.String.Regex as Rgx
import qualified Data.Argonaut.Parser as Ap
import qualified Network.HTTP.Affjax.Response as Ar
import qualified Network.HTTP.Affjax.ResponseType as At
import qualified Network.HTTP.Affjax as Af

import qualified Config as Config
import qualified Model as M
import qualified Model.Item as Mi
import qualified Model.Resource as Mr
import qualified Model.Notebook as Mn

newtype Listing = Listing [Child]

instance listingIsForeign :: IsForeign Listing where
  read f = Listing <$> readProp "children" f

newtype Child = Child {name :: String, resource :: Mr.Resource}

instance childIsForeign :: IsForeign Child where
  read f = Child <$> 
    ({name: _, resource: _} <$>
     readProp "name" f <*>
     readProp "type" f)


instance listingResponsable :: Ar.Responsable Listing where
  responseType _ = At.JSONResponse
  fromResponse = read

listing2items :: Listing -> [Mi.Item]
listing2items (Listing cs) =
  child2item <$> cs
  where nbExtensionRgx = Rgx.regex ("\\" <> Config.notebookExtension) Rgx.noFlags
        isNotebook r = r.resource == Mr.File &&
                     r.name ==
                     Rgx.replace nbExtensionRgx "" r.name
        child2item (Child r) =
          let item = {
                resource: r.resource,
                name: r.name,
                selected: false,
                hovered: false,
                phantom: false,
                root: ""
                }
          in if isNotebook r then
               item{resource = Mr.Notebook}
             else item


listing' :: forall e. String -> Af.Affjax e Listing
listing' path = Af.get (Config.metadataUrl <> path)

listing :: forall e. String -> Aff.Aff (ajax::Af.Ajax|e) [Mi.Item]
listing path = (listing2items <<< _.response) <$> listing' path

makeFile :: forall e. String -> String -> Af.Affjax e Unit
makeFile path content =
  let isJson = either (const false) (const true) do
        hd <- maybe (Left "empty file") Right $
              Arr.head $ Str.split "\n" content
        Ap.jsonParser hd
  in if isJson then do 
    Af.put_ (Config.dataUrl <> path) content
    else throwError $ error "file has incorrect format" 
                        
makeNotebook :: forall e. Af.URL -> Mn.Notebook -> Af.Affjax e Unit 
makeNotebook path notebook = Af.put_ (Config.dataUrl <> path) notebook

delete :: forall e. String -> Af.Affjax e Unit
delete path = Af.delete_ (Config.dataUrl <> path)

deleteItem :: forall e. Mi.Item -> Af.Affjax e Unit
deleteItem item =
    let path = item.root <> item.name <>
               if item.resource /= Mr.File && item.resource /= Mr.Notebook then "/"
               else ""
    in delete path 
