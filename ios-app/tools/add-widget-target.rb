# Xcode プロジェクトに WidgetKit 拡張（HimekuriWidget）と App Group を組み込む。
# 使い方（ios-app/ で）:
#   GEM_HOME=/opt/homebrew/Cellar/cocoapods/1.17.0/libexec /opt/homebrew/opt/ruby/bin/ruby tools/add-widget-target.rb
# 一度組み込めば再実行は不要（再実行しても二重には追加しない）。
require 'xcodeproj'

path = File.expand_path('../ios/App/App.xcodeproj', __dir__)
proj = Xcodeproj::Project.open(path)
app = proj.targets.find { |t| t.name == 'App' } or abort('App target not found')

# ---- App 側: 橋渡しプラグインと entitlements ----
app_group = proj.main_group['App'] or abort('App group not found')
def ensure_file(group, name)
  group.files.find { |f| f.path == name } || group.new_file(name)
end
%w[WidgetBridgePlugin.swift AppViewController.swift].each do |n|
  ref = ensure_file(app_group, n)
  app.add_file_references([ref]) unless app.source_build_phase.files_references.include?(ref)
end
ensure_file(app_group, 'App.entitlements')
app.build_configurations.each do |c|
  c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'App/App.entitlements'
  c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
end

# ---- Widget 拡張ターゲット ----
widget = proj.targets.find { |t| t.name == 'HimekuriWidget' }
unless widget
  widget = proj.new_target(:app_extension, 'HimekuriWidget', :ios, '16.0', proj.products_group, :swift)
  wgroup = proj.main_group['Widget'] || proj.main_group.new_group('Widget', 'Widget')
  srcs = %w[HimekuriWidget.swift HimekuriData.swift].map { |n| ensure_file(wgroup, n) }
  widget.add_file_references(srcs)
  ensure_file(wgroup, 'Info.plist')
  ensure_file(wgroup, 'Widget.entitlements')
  widget.build_configurations.each do |c|
    bs = c.build_settings
    bs['INFOPLIST_FILE'] = 'Widget/Info.plist'
    bs['GENERATE_INFOPLIST_FILE'] = 'NO'
    bs['PRODUCT_BUNDLE_IDENTIFIER'] = 'work.ltv.himekuri.widget'
    bs['PRODUCT_NAME'] = '$(TARGET_NAME)'
    bs['CODE_SIGN_ENTITLEMENTS'] = 'Widget/Widget.entitlements'
    bs['CODE_SIGN_STYLE'] = 'Automatic'
    bs['SKIP_INSTALL'] = 'YES'
    bs['SWIFT_VERSION'] = '5.0'
    bs['TARGETED_DEVICE_FAMILY'] = '1,2'
    bs['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    bs['MARKETING_VERSION'] = '1.0'
    bs['CURRENT_PROJECT_VERSION'] = '1'
    bs['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
    bs['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
    bs['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
    bs['ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME'] = 'WidgetBackground'
    bs.delete('ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME')
    bs.delete('ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME')
  end
  # WidgetKit / SwiftUI は自動リンク（import）で足りるので frameworks phase への追加は不要

  # App に組み込む（Embed Foundation Extensions → PlugIns/）
  app.add_dependency(widget)
  embed = app.copy_files_build_phases.find { |p| p.name == 'Embed Foundation Extensions' } || app.new_copy_files_build_phase('Embed Foundation Extensions')
  embed.dst_subfolder_spec = '13'
  embed.dst_path = ''
  unless embed.files_references.include?(widget.product_reference)
    bf = embed.add_file_reference(widget.product_reference)
    bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  end
end

proj.save
puts "targets: #{proj.targets.map(&:name).join(', ')}"
puts "App sources: #{app.source_build_phase.files_references.map(&:path).join(', ')}"
puts "Widget sources: #{widget.source_build_phase.files_references.map(&:path).join(', ')}"
puts "Embed: #{app.copy_files_build_phases.map { |p| "#{p.name}(#{p.dst_subfolder_spec}) #{p.files_references.map(&:path).join(',')}" }.join(' | ')}"
puts "App deps: #{app.dependencies.map { |d| d.target.name }.join(', ')}"
