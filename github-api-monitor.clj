#!/usr/bin/env bb

;;
;; GitHub GraphQL API Rate Limit Monitor - Babashka Version
;;
;; A comprehensive script to monitor GitHub GraphQL API rate limits and usage.
;; Provides detailed information about your current API consumption, remaining
;; quota, reset times, and helpful recommendations.
;;
;; This is the Babashka-optimized version that leverages Clojure's powerful
;; features and babashka's built-in libraries for a more concise implementation.
;;
;; Usage: ./github-api-monitor.clj [OPTIONS]
;;
;; Author: Open Source Community
;; License: MIT
;; Version: 1.0.0
;;

(ns github-api-monitor
  (:require [clojure.string :as str]
            [cheshire.core :as json]
            [babashka.cli :as cli]
            [babashka.http-client :as http]
            [babashka.fs :as fs])
  (:import [java.time Instant ZonedDateTime ZoneId]
           [java.time.format DateTimeFormatter]))

;; Check for required dependencies
(defn check-dependencies []
  (try
    ;; Test critical dependencies
    (require '[cheshire.core])
    (require '[babashka.cli])
    (require '[babashka.http-client])
    (require '[babashka.fs])
    true
    (catch Exception e
      (binding [*out* *err*]
        (println (str "\033[0;31m[ERROR]\033[0m Missing required dependency: " (.getMessage e)))
        (println "This script requires babashka with standard libraries."))
      (System/exit 3))))

;; Script metadata
(def script-name "github-api-monitor.clj")
(def script-version "1.0.0")
(def script-description "GitHub GraphQL API Rate Limit Monitor (Babashka)")

;; Configuration
(def default-config-file (str (System/getProperty "user.home") "/.github-api-monitor"))
(def github-api-url "https://api.github.com/graphql")

;; Status thresholds configuration
(def status-thresholds
  {:critical 90
   :high     75
   :medium   50
   :low      0})

;; Regex for terminal types supporting ANSI colors
(def ansi-term-regex #"^(xterm|screen|vt100|rxvt|linux|ansi|cygwin)")

;; Terminal support detection
(defn supports-ansi? []
  (and (System/console)
       (re-find ansi-term-regex (or (System/getenv "TERM") ""))))

;; ANSI color codes
(def colors
  (if (supports-ansi?)
    {:red    "\033[0;31m"
     :green  "\033[0;32m"
     :yellow "\033[0;33m"
     :blue   "\033[0;34m"
     :cyan   "\033[0;36m"
     :bold   "\033[1m"
     :reset  "\033[0m"}
    {:red "" :green "" :yellow "" :blue "" :cyan "" :bold "" :reset ""}))

;; Global state atom for configuration
(def config (atom {:github-token nil
                   :output-format "table"
                   :verbose false
                   :show-headers false
                   :continuous-mode false
                   :refresh-interval 60
                   :config-file nil}))

;; Screen clearing function
(defn clear-screen []
  (when (and (= "table" (:output-format @config))
             (supports-ansi?))
    (print "\033[2J\033[H")))

;; Logging functions
(defn log-error [msg]
  (binding [*out* *err*]
    (println (str (:red colors) "[ERROR]" (:reset colors) " " msg))))

(defn log-info [msg]
  (binding [*out* *err*]
    (println (str (:blue colors) "[INFO]" (:reset colors) " " msg))))

(defn log-debug [msg]
  (when (:verbose @config)
    (binding [*out* *err*]
      (println (str "[DEBUG] " msg)))))

;; CLI specification
(def cli-spec
  {:token    {:desc "GitHub personal access token"
              :alias :t
              :coerce :string}
   :format   {:desc "Output format: table, json, compact"
              :alias :f
              :coerce :string
              :default "table"
              :validate #{"table" "json" "compact"}}
   :config   {:desc "Configuration file path"
              :alias :c
              :coerce :string}
   :watch    {:desc "Continuous monitoring mode"
              :alias :w
              :coerce :boolean}
   :interval {:desc "Refresh interval for watch mode (seconds)"
              :alias :i
              :coerce :int
              :default 60
              :validate pos-int?}
   :headers  {:desc "Show raw HTTP headers"
              :alias :H
              :coerce :boolean}
   :verbose  {:desc "Enable verbose output"
              :alias :v
              :coerce :boolean}
   :help     {:desc "Show help message"
              :alias :h
              :coerce :boolean}
   :version  {:desc "Show version information"
              :coerce :boolean}})

(defn show-help []
  (println (str (:bold colors) script-name (:reset colors) " - " script-description))
  (println)
  (println (str (:bold colors) "USAGE:" (:reset colors)))
  (println (str "    " script-name " [OPTIONS]"))
  (println)
  (println (str (:bold colors) "DESCRIPTION:" (:reset colors)))
  (println "    Monitor your GitHub GraphQL API rate limits and usage. This script provides")
  (println "    detailed information about your current API consumption, remaining quota,")
  (println "    reset times, and helpful recommendations for staying within limits.")
  (println)
  (println "    This is the Babashka-optimized version using Clojure's powerful features.")
  (println)
  (println (str (:bold colors) "OPTIONS:" (:reset colors)))
  (println "    -t, --token TOKEN       GitHub personal access token (required)")
  (println "    -f, --format FORMAT     Output format: table, json, compact (default: table)")
  (println "    -c, --config FILE       Configuration file path (default: ~/.github-api-monitor)")
  (println "    -w, --watch             Continuous monitoring mode")
  (println "    -i, --interval SECONDS  Refresh interval for watch mode (default: 60)")
  (println "    -H, --headers           Show raw HTTP headers")
  (println "    -v, --verbose           Enable verbose output")
  (println "    -h, --help              Show this help message")
  (println "    --version               Show version information")
  (println)
  (println (str (:bold colors) "EXAMPLES:" (:reset colors)))
  (println "    # Basic usage with token")
  (println (str "    " script-name " --token ghp_xxxxxxxxxxxxxxxxxxxx"))
  (println)
  (println "    # Continuous monitoring with 30-second intervals")
  (println (str "    " script-name " --token ghp_xxxxxxxxxxxxxxxxxxxx --watch --interval 30"))
  (println)
  (println "    # JSON output for scripting")
  (println (str "    " script-name " --token ghp_xxxxxxxxxxxxxxxxxxxx --format json"))
  (println)
  (println "    # Verbose mode with headers")
  (println (str "    " script-name " --token ghp_xxxxxxxxxxxxxxxxxxxx --verbose --headers"))
  (println)
  (println (str (:bold colors) "TOKEN REQUIREMENTS:" (:reset colors)))
  (println "    Your GitHub personal access token needs basic access to query the GraphQL API.")
  (println "    Both classic personal access tokens and fine-grained tokens are supported.")
  (println)
  (println (str (:bold colors) "CONFIGURATION:" (:reset colors)))
  (println "    You can store your token in a configuration file to avoid passing it")
  (println "    each time. Create ~/.github-api-monitor with:")
  (println)
  (println "    GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx")
  (println)
  (println (str (:bold colors) "ENVIRONMENT VARIABLES:" (:reset colors)))
  (println "    GITHUB_TOKEN            GitHub personal access token")
  (println "    GITHUB_API_MONITOR_CONFIG   Alternative config file path")
  (println)
  (println (str (:bold colors) "EXIT CODES:" (:reset colors)))
  (println "    0    Success")
  (println "    1    General error")
  (println "    2    Invalid arguments")
  (println "    3    Missing dependencies")
  (println "    4    Authentication error")
  (println "    5    API error")
  (println)
  (println "For more information, visit: https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api"))

(defn show-version []
  (println (str script-name " " script-version)))

;; Configuration management
(defn load-config-file [config-file]
  (let [file (or config-file
                 (System/getenv "GITHUB_API_MONITOR_CONFIG")
                 default-config-file)]
    (when (fs/exists? file)
      (try
        (let [file-path (fs/path file)
              posix-attrs (fs/posix-file-permissions file-path)]
          (when (contains? posix-attrs :group_read)
            (log-error (str "Config file " file " is readable by group. Please restrict permissions to owner only."))
            (System/exit 1))
          (when (contains? posix-attrs :other_read)
            (log-error (str "Config file " file " is readable by others. Please restrict permissions to owner only."))
            (System/exit 1)))
        (catch Exception e
          (log-debug (str "Could not check config file permissions: " (.getMessage e)))))
      (try
        (log-debug (str "Loading configuration from " file))
        (let [content (slurp file)
              lines (str/split-lines content)]
          (doseq [line lines]
            (when-let [[_ token] (re-matches #"^GITHUB_TOKEN=(.+)$" (str/trim line))]
              (when (re-matches #"^(gh[pou]_|ghr_|ghs_|github_pat_).+" token)
                (swap! config assoc :github-token token)
                (log-debug "Token loaded from config file")))))
        (catch Exception e
          (log-error (str "Failed to read config file: " (.getMessage e)))
          (System/exit 1))))
    file))

(defn handle-validation-error [e]
  (let [data (ex-data e)
        class-name (str (class e))
        msg (.getMessage e)]
    (cond
      ;; Handle HTTP status errors from ex-data
      (and data (:status data))
      (let [status (:status data)]
        (cond
          (= status 401)
          (log-error "Token validation failed: Unauthorized (401). The token is invalid or expired.")

          (= status 403)
          (log-error "Token validation failed: Forbidden (403). The token does not have sufficient permissions.")

          :else
          (log-error (str "Failed to validate token: " msg))))

      ;; Handle network errors
      (or (str/includes? class-name "UnknownHostException")
          (str/includes? msg "UnknownHostException"))
      (do
        (log-error "Network error: Unable to resolve api.github.com. Check your internet connection.")
        (System/exit 1))

      (or (str/includes? class-name "SocketTimeoutException")
          (str/includes? msg "timed out"))
      (do
        (log-error "Network error: Connection to api.github.com timed out.")
        (System/exit 1))

      ;; Default case
      :else
      (log-error (str "Unexpected error during token validation: " msg)))

    (System/exit 4)))

(defn validate-token []
  (let [token (:github-token @config)]
    (when (str/blank? token)
      (log-error "GitHub token is required")
      (log-error "Provide it via --token, config file, or GITHUB_TOKEN environment variable")
      (System/exit 4))

    (log-debug "Validating token...")
    (try
      (let [response (http/get "https://api.github.com/user"
                               {:headers {"Authorization" (str "Bearer " token)
                                          "User-Agent" (str script-name "/" script-version)}})
            status (:status response)]
        (cond
          (= status 200)
          (let [body (json/parse-string (:body response) true)
                username (:login body)]
            (log-debug (str "Token validated for user: " username)))

          (= status 401)
          (do
            (log-error "Token validation failed: Unauthorized (401). The token is invalid or expired.")
            (System/exit 4))

          (= status 403)
          (do
            (log-error "Token validation failed: Forbidden (403). The token does not have sufficient permissions.")
            (System/exit 4))

          :else
          (do
            (log-error (str "Token validation failed: Unexpected HTTP status " status))
            (System/exit 4))))
      (catch Exception e
        (handle-validation-error e)))))
;; Data processing functions
(defn calculate-usage-percentage [used limit]
  (if (zero? limit)
    0.0
    (double (* 100 (/ used limit)))))

(defn extract-rate-limit-data
  "Extract common data from GraphQL response"
  [data]
  (let [viewer-login (get-in data [:data :viewer :login])
        rate-limit (get-in data [:data :rateLimit])
        {:keys [limit remaining used resetAt cost]} rate-limit
        usage-percentage (calculate-usage-percentage used limit)]
    {:viewer-login viewer-login
     :limit limit
     :remaining remaining
     :used used
     :resetAt resetAt
     :cost cost
     :usage-percentage usage-percentage}))

(defn get-status-level
  "Get status level based on usage percentage"
  [percentage]
  (cond
    (>= percentage (:critical status-thresholds)) :critical
    (>= percentage (:high status-thresholds)) :high
    (>= percentage (:medium status-thresholds)) :medium
    :else :low))

(defn format-timestamp [timestamp]
  (let [instant (Instant/parse timestamp)
        zdt (ZonedDateTime/ofInstant instant (ZoneId/of "UTC"))
        formatter (DateTimeFormatter/ofPattern "yyyy-MM-dd HH:mm:ss 'UTC'")]
    (.format zdt formatter)))

(defn calculate-time-remaining [reset-time]
  (try
    (let [reset-instant (Instant/parse reset-time)
          now (Instant/now)
          diff-seconds (.toSeconds (java.time.Duration/between now reset-instant))]
      (cond
        (<= diff-seconds 0) "Now"
        (< diff-seconds 60) (str diff-seconds "s")
        (< diff-seconds 3600) (str (quot diff-seconds 60) "m")
        :else (str (quot diff-seconds 3600) "h")))
    (catch Exception _
      "Unknown")))

(defn get-usage-status
  "Get colored usage status string based on percentage"
  [percentage]
  (let [level (get-status-level percentage)
        color-map {:critical :red
                   :high     :yellow
                   :medium   :blue
                   :low      :green}
        status-map {:critical "Critical"
                    :high     "High"
                    :medium   "Medium"
                    :low      "Low"}
        color (get color-map level)
        status (get status-map level)]
    (str (color colors) status (:reset colors))))

;; API interaction
(defn make-graphql-request [query]
  (log-debug (str "Making GraphQL request to " github-api-url))
  (try
    (let [token (:github-token @config)
          response (http/post github-api-url
                              {:headers {"Authorization" (str "Bearer " token)
                                         "Content-Type" "application/json"
                                         "User-Agent" (str script-name "/" script-version)}
                               :body (json/generate-string {:query query})})]

      (when (:show-headers @config)
        (println)
        (println (str (:bold colors) "HTTP Headers:" (:reset colors)))
        (doseq [[k v] (:headers response)]
          (println (str k ": " v)))
        (println))

      (let [body (json/parse-string (:body response) true)]
        (if (:errors body)
          (do
            (log-error "GraphQL API returned errors:")
            (doseq [error (:errors body)]
              (println (str "  - " (:message error))))
            (System/exit 5))
          body)))
    (catch Exception e
      (log-error (str "Network error: " (.getMessage e)))
      (System/exit 1))))

(defn get-rate-limit-info []
  (let [query "query { viewer { login } rateLimit { limit remaining used resetAt cost } }"]
    (make-graphql-request query)))

;; Output formatting
(defn format-table-output [data]
  (let [{:keys [viewer-login limit remaining used resetAt cost usage-percentage]}
        (extract-rate-limit-data data)
        reset-formatted (format-timestamp resetAt)
        time-remaining (calculate-time-remaining resetAt)
        usage-status (get-usage-status usage-percentage)]

    (println)
    (println (str (:bold colors) "GitHub GraphQL API Rate Limit Status" (:reset colors)))
    (println (str (:bold colors) "=====================================" (:reset colors)))
    (println)
    (printf "%-20s %s%s%s\n" "User:" (:cyan colors) viewer-login (:reset colors))
    (printf "%-20s %s\n" "Current Time:"
            (.format (ZonedDateTime/now (ZoneId/of "UTC"))
                     (DateTimeFormatter/ofPattern "yyyy-MM-dd HH:mm:ss 'UTC'")))
    (println)
    (println (str (:bold colors) "Rate Limit Information:" (:reset colors)))
    (printf "%-20s %s\n" "Limit:" (str limit " points/hour"))
    (printf "%-20s %s\n" "Used:" (format "%d points (%.1f%%)" used usage-percentage))
    (printf "%-20s %s\n" "Remaining:" (str remaining " points"))
    (printf "%-20s %s\n" "Status:" usage-status)
    (printf "%-20s %s\n" "Query Cost:" (str cost " points"))
    (println)
    (println (str (:bold colors) "Reset Information:" (:reset colors)))
    (printf "%-20s %s\n" "Reset Time:" reset-formatted)
    (printf "%-20s %s\n" "Time Remaining:" time-remaining)

    ;; Recommendations
    (println)
    (println (str (:bold colors) "Recommendations:" (:reset colors)))
    (let [level (get-status-level usage-percentage)]
      (case level
        :critical
        (do
          (println (str (:red colors) "⚠" (:reset colors) "  Critical usage! Consider:"))
          (println "   • Pause non-essential API calls")
          (println "   • Wait for rate limit reset")
          (println "   • Optimize queries to use fewer points"))

        :high
        (do
          (println (str (:yellow colors) "⚠" (:reset colors) "  High usage. Consider:"))
          (println "   • Monitor usage closely")
          (println "   • Reduce query complexity")
          (println "   • Use smaller page sizes"))

        (println (str (:green colors) "✓" (:reset colors) "  Usage is within normal limits"))))

    (println)
    (println "For more information, visit:")
    (println "https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api")))

(defn format-json-output [data]
  (let [{:keys [viewer-login limit remaining used resetAt cost usage-percentage]}
        (extract-rate-limit-data data)
        status (name (get-status-level usage-percentage))]
    (println (json/generate-string
              {:timestamp (.toString (Instant/now))
               :user viewer-login
               :rateLimit {:limit limit
                           :used used
                           :remaining remaining
                           :usagePercentage (format "%.2f" usage-percentage)
                           :resetAt resetAt
                           :resetAtFormatted (format-timestamp resetAt)
                           :cost cost}
               :status status}
              {:pretty true}))))

(defn format-compact-output [data]
  (let [{:keys [viewer-login limit remaining used usage-percentage]}
        (extract-rate-limit-data data)]
    (printf "%s: %d/%d (%.1f%%) - %d remaining\n"
            viewer-login used limit usage-percentage remaining)
    (flush)))

;; Main monitoring functions
(defn monitor-once []
  (log-debug "Fetching rate limit information...")
  (let [response (get-rate-limit-info)]
    (clear-screen)

    (case (:output-format @config)
      "json"    (format-json-output response)
      "compact" (format-compact-output response)
      (format-table-output response))))

(defn monitor-continuous []
  (log-info (str "Starting continuous monitoring (refresh every "
                 (:refresh-interval @config) "s)"))
  (log-info "Press Ctrl+C to stop")

  ;; Add shutdown hook
  (.addShutdownHook (Runtime/getRuntime)
                    (Thread. #(log-info "Monitoring stopped")))

  (loop []
    (clear-screen)

    (monitor-once)

    (when (not= "table" (:output-format @config))
      (println "---"))

    (Thread/sleep (* 1000 (:refresh-interval @config)))
    (recur)))

;; Main entry point
(defn -main [& args]
  ;; Check dependencies first
  (check-dependencies)

  (let [opts (try
               (cli/parse-opts (vec args) {:spec cli-spec})
               (catch Exception e
                 (log-error (str "Invalid arguments: " (.getMessage e)))
                 (System/exit 2)))]
    ;; Handle help and version
    (when (:help opts)
      (show-help)
      (System/exit 0))

    (when (:version opts)
      (show-version)
      (System/exit 0))

    ;; Update config with CLI options
    (swap! config merge
           {:output-format (or (:format opts) "table")
            :verbose (:verbose opts)
            :show-headers (:headers opts)
            :continuous-mode (:watch opts)
            :refresh-interval (or (:interval opts) 60)})

    ;; Load config file
    (load-config-file (:config opts))

    ;; Override with CLI token if provided
    (when-let [cli-token (:token opts)]
      (swap! config assoc :github-token cli-token))

    ;; Also check environment variable
    (when (str/blank? (:github-token @config))
      (when-let [env-token (System/getenv "GITHUB_TOKEN")]
        (swap! config assoc :github-token env-token)))

    ;; Validate token
    (validate-token)

    ;; Run monitoring
    (try
      (if (:continuous-mode @config)
        (monitor-continuous)
        (monitor-once))
      (System/exit 0)
      (catch Exception e
        (log-error (str "Unexpected error: " (.getMessage e)))
        (when (:verbose @config)
          (.printStackTrace e System/err))))))
;; Entry point
;; This ensures that the entry point logic only runs when the script is executed directly,
;; not when it's loaded as a library or required by another script.
(when (= *file* (System/getProperty "babashka.file"))
  (apply -main *command-line-args*))