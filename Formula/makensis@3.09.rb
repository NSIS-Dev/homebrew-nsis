class MakensisAT309 < Formula
  desc "System to create Windows installers"
  homepage "https://nsis.sourceforge.io/"
  url "https://downloads.sourceforge.net/project/nsis/NSIS%203/3.09/nsis-3.09-src.tar.bz2"
  sha256 "0cd846c6e9c59068020a87bfca556d4c630f2c5d554c1098024425242ddc56e2"
  license "Zlib"

  option "with-advanced-logging", "Enable advanced logging of all installer actions"
  option "with-large-strings", "Enable strings up to 8192 characters instead of default 1024"
  option "with-debug", "Build executables with debugging information"

  depends_on "mingw-w64" => :build
  depends_on "scons@4.7.0" => :build

  resource "nsis" do
    url "https://downloads.sourceforge.net/project/nsis/NSIS%203/3.09/nsis-3.09.zip"
    sha256 "f5dc52eef1f3884230520199bac6f36b82d643d86b003ce51bd24b05c6ba7c91"
  end

  if build.with?("large-strings")
    resource "nsis-strlen" do
      url "https://downloads.sourceforge.net/project/nsis/NSIS%203/3.09/nsis-3.09-strlen_8192.zip"
      sha256 "9e3b8e77c97a46747201f95f89eba26714dd9c6dc06830c3934b3f5fbdb1beca"
    end
  end

  def install
    args = [
      "CC=#{ENV.cc}",
      "CXX=#{ENV.cxx}",
      "PREFIX=#{prefix}",
      "PREFIX_DOC=#{share}/nsis/Docs",
      "SKIPUTILS=Makensisw,NSIS Menu,zip2exe",
      # Don't strip, see https://github.com/Homebrew/homebrew/issues/28718
      "STRIP=0",
      "VERSION=#{version}",
    ]

    args << "NSIS_CONFIG_LOG=yes" if build.with? "advanced-logging"
    args << "NSIS_MAX_STRLEN=8192" if build.with? "large-strings"
    args << "DEBUG=1" if build.with? "debug"
    args << "APPEND_LINKFLAGS=-Wl,-rpath,#{rpath}" if OS.linux?

    system "scons", "makensis", *args

    install_path = if build.with? "debug"
      "build/udebug/makensis/makensis"
    else
      "build/urelease/makensis/makensis"
    end

    bin.install install_path
    (share/"nsis").install resource("nsis-strlen") if build.with?("large-strings")
    (share/"nsis").install resource("nsis")
  end

  test do
    # Workaround for https://sourceforge.net/p/nsis/bugs/1165/
    ENV["LANG"] = "en_GB.UTF-8"
    %w[COLLATE CTYPE MESSAGES MONETARY NUMERIC TIME].each do |lc_var|
      ENV["LC_#{lc_var}"] = "en_GB.UTF-8"
    end

    system "#{bin}/makensis", "-VERSION"
    system "#{bin}/makensis", "-HDRINFO"
    system "#{bin}/makensis", "-XUnicode false", "#{share}/nsis/Examples/bigtest.nsi", "-XOutfile /dev/null"
  end
end
