pipeline {
    agent none

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    parameters {
        booleanParam(name: 'BUILD_ANDROID', defaultValue: true, description: 'Android bauen und auf main zuerst in Google Play veröffentlichen')
        booleanParam(name: 'BUILD_IOS', defaultValue: false, description: 'iOS erst im anschließenden separaten Durchlauf bauen')
    }

    environment {
        APP_ID = 'de.anesda.crmspeedphone.dialer'
        APP_NAME = 'SpeedPhone Dialer'
        APPLE_TEAM_ID = 'L58YPB7N96'
        ASC_KEY_ID = '3UAHYXXN57'
        ASC_ISSUER_ID = 'b5d39544-6e47-45ea-b2d6-27b1dd6cb5fa'
        ASC_KEY_PATH = '/Users/danieleschenlohr/.appstoreconnect/private_keys/AuthKey_3UAHYXXN57.p8'
    }

    stages {
        stage('Quellcode und Version') {
            agent { label 'windows' }
            steps {
                checkout scm
                script {
                    env.BRANCH_NAME_CLEAN = (env.BRANCH_NAME ?: env.GIT_BRANCH ?: 'beta').replaceFirst(/^origin\//, '')
                    env.IS_MAIN = env.BRANCH_NAME_CLEAN == 'main' ? 'true' : 'false'
                    env.VERSION_NAME = "1.0.${env.BUILD_NUMBER}"
                    env.VERSION_CODE = "${System.currentTimeMillis().intdiv(10000L)}"
                }
                stash name: 'speedphone-source', includes: '**/*', excludes: '.git/**,build/**,.dart_tool/**,android/.gradle/**,android/key.properties,android/release.keystore'
            }
        }

        stage('Android') {
            agent { label 'windows' }
            when { expression { params.BUILD_ANDROID } }
            stages {
                stage('Android vorbereiten') {
                    steps {
                        withCredentials([
                            file(credentialsId: 'release.keystore', variable: 'KEYSTORE_FILE'),
                            string(credentialsId: 'keystore-password', variable: 'STORE_PASSWORD'),
                            string(credentialsId: 'key-alias', variable: 'KEY_ALIAS'),
                            string(credentialsId: 'key-password', variable: 'KEY_PASSWORD')
                        ]) {
                            powershell '''
                                $ErrorActionPreference = 'Stop'
                                Copy-Item -LiteralPath $env:KEYSTORE_FILE -Destination 'android/release.keystore' -Force
                                $keyProperties = @"
storeFile=../release.keystore
storePassword=$env:STORE_PASSWORD
keyAlias=$env:KEY_ALIAS
keyPassword=$env:KEY_PASSWORD
"@
                                [IO.File]::WriteAllText(
                                    (Join-Path $PWD 'android/key.properties'),
                                    $keyProperties,
                                    [Text.UTF8Encoding]::new($false)
                                )
                                & 'C:/flutter/bin/flutter.bat' pub get
                                & 'C:/flutter/bin/dart.bat' run flutter_launcher_icons
                            '''
                        }
                    }
                }
                stage('Analyse und Tests') {
                    steps {
                        powershell '''
                            $ErrorActionPreference = 'Stop'
                            & 'C:/flutter/bin/flutter.bat' analyze
                            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
                            & 'C:/flutter/bin/flutter.bat' test
                            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
                        '''
                    }
                }
                stage('APK und App Bundle') {
                    steps {
                        powershell '''
                            $ErrorActionPreference = 'Stop'
                            & 'C:/flutter/bin/flutter.bat' build apk --release --build-name=$env:VERSION_NAME --build-number=$env:VERSION_CODE
                            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
                            & 'C:/flutter/bin/flutter.bat' build appbundle --release --build-name=$env:VERSION_NAME --build-number=$env:VERSION_CODE
                            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
                        '''
                    }
                    post {
                        success {
                            archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/*.apk,build/app/outputs/bundle/release/*.aab', fingerprint: true
                        }
                    }
                }
                stage('Google Play') {
                    when { expression { env.IS_MAIN == 'true' } }
                    steps {
                        withCredentials([file(credentialsId: 'play-store-service-account', variable: 'PLAY_SERVICE_ACCOUNT_JSON')]) {
                            powershell '''
                                $ErrorActionPreference = 'Stop'
                                Push-Location android
                                try {
                                    & './gradlew.bat' :app:publishReleaseListing --no-daemon
                                    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
                                    & './gradlew.bat' :app:publishReleaseBundle --track=internal --release-status=completed --artifact-dir=../build/app/outputs/bundle/release --no-daemon
                                    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
                                } finally { Pop-Location }
                            '''
                        }
                    }
                }
            }
            post {
                always {
                    powershell "Remove-Item -LiteralPath 'android/key.properties','android/release.keystore' -Force -ErrorAction SilentlyContinue"
                }
            }
        }

        stage('iOS') {
            agent { label 'mac' }
            when { expression { params.BUILD_IOS } }
            options { skipDefaultCheckout(true) }
            steps {
                sh '''#!/bin/bash -l
                    set -euo pipefail
                    rm -rf ./* ./.[!.]* 2>/dev/null || true
                '''
                unstash 'speedphone-source'
                sh '''#!/bin/bash -l
                    set -euo pipefail
                    export PATH="/opt/homebrew/bin:$HOME/flutter/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
                    export LANG=en_US.UTF-8
                    export LC_ALL=en_US.UTF-8
                    flutter pub get
                    dart run flutter_launcher_icons
                    flutter analyze
                    flutter test
                    flutter build ipa --release --build-name="${VERSION_NAME}" --build-number="${BUILD_NUMBER}" --export-method app-store
                    ls -la build/ios/ipa
                '''
                script {
                    if (env.IS_MAIN == 'true') {
                        sh '''#!/bin/bash -l
                            set -euo pipefail
                            IPA=$(find build/ios/ipa -name '*.ipa' -type f | head -1)
                            test -n "$IPA"
                            xcrun altool --upload-app -f "$IPA" -t ios --apiKey "${ASC_KEY_ID}" --apiIssuer "${ASC_ISSUER_ID}"
                        '''
                    }
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'build/ios/ipa/*.ipa', fingerprint: true, allowEmptyArchive: true
                }
            }
        }
    }

    post {
        always {
            echo "${APP_NAME} ${VERSION_NAME}: ${currentBuild.currentResult}"
        }
    }
}
