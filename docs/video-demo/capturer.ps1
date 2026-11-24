<#
  Captures d'écran et enregistrements vidéo de l'app PGDE sur la tablette,
  pour la vidéo de démonstration Remotion.

  Utilisation (depuis la racine du projet, tablette branchée, app installée) :
    .\docs\video-demo\capturer.ps1 -Image 01-splash
    .\docs\video-demo\capturer.ps1 -Video parcours-formulaire -Secondes 60

  -Image  : prend une capture de l'écran affiché, enregistrée en PNG.
  -Video  : filme l'écran pendant -Secondes (180 max, limite d'Android),
            puis rapatrie le MP4. Pendant l'enregistrement, fais le parcours
            à la main sur la tablette, lentement et sans hésiter.

  Rendu smartphone sur la tablette (la vidéo ne montre que le mobile) :
    .\docs\video-demo\capturer.ps1 -ModeTelephone   # avant les captures
    .\docs\video-demo\capturer.ps1 -Retablir        # après, pour rendre la tablette
  -ModeTelephone règle l'écran sur 1080 × 2340 à 440 dpi, soit environ 393 dp
  de large, comme un Android courant. L'app affiche alors sa vraie mise en
  page téléphone. Relance l'app après le changement : l'orientation est
  décidée au démarrage.

  Conseils de tournage :
  - Utilise un compte de DÉMO aux données fictives : aucune vraie adresse
    e-mail, aucun vrai numéro de CNI ou de téléphone ne doit apparaître.
  - Batterie chargée, Wi-Fi stable, mode Ne pas déranger activé : aucune
    notification ne doit traverser l'écran.
  - Active « Afficher les appuis » (Options pour les développeurs) pour que
    les touchers soient visibles dans les enregistrements.
#>
param(
  [string]$Image,
  [string]$Video,
  [ValidateRange(5, 180)][int]$Secondes = 30,
  [string]$Appareil = 'HVA6NDGA',
  [switch]$ModeTelephone,
  [switch]$Retablir
)

$ErrorActionPreference = 'Stop'
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path $adb)) { $adb = 'adb' }

if ($ModeTelephone) {
  & $adb -s $Appareil shell wm size 1080x2340
  & $adb -s $Appareil shell wm density 440
  Write-Host 'Écran en mode smartphone. Relance l''app, puis capture.'
}
if ($Retablir) {
  & $adb -s $Appareil shell wm size reset
  & $adb -s $Appareil shell wm density reset
  Write-Host 'Écran de la tablette rétabli.'
}

$dossierImages = Join-Path $PSScriptRoot 'captures'
$dossierVideos = Join-Path $PSScriptRoot 'enregistrements'
New-Item -ItemType Directory -Force $dossierImages, $dossierVideos | Out-Null

if ($Image) {
  $sortie = Join-Path $dossierImages "$Image.png"
  # `exec-out` transmet le PNG brut, sans la conversion de fins de ligne
  # qui corromprait l'image avec `adb shell`.
  & cmd /c "`"$adb`" -s $Appareil exec-out screencap -p > `"$sortie`""
  Write-Host "Capture enregistrée : $sortie"
}

if ($Video) {
  $distant = "/sdcard/$Video.mp4"
  $sortie = Join-Path $dossierVideos "$Video.mp4"
  Write-Host "Enregistrement pendant $Secondes s — fais le parcours maintenant…"
  & $adb -s $Appareil shell screenrecord --bit-rate 12000000 --time-limit $Secondes $distant
  & $adb -s $Appareil pull $distant $sortie | Out-Null
  & $adb -s $Appareil shell rm $distant
  Write-Host "Vidéo enregistrée : $sortie"
}

if (-not $Image -and -not $Video -and -not $ModeTelephone -and -not $Retablir) {
  Write-Host 'Précise -Image <nom> ou -Video <nom>. Voir l''aide en tête de script.'
}
