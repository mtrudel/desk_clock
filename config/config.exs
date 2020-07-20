import Config

config :desk_clock, target: Mix.target()

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"
config :nerves, source_date_epoch: "1595268058"

config :logger, backends: [RingLogger]

if Mix.target() != :host do
  import_config "target.exs"
end
