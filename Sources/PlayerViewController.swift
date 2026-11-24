import UIKit
import AVFoundation
import MediaPlayer

final class PlayerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate {
    private let lib = Library.shared
    private var player: AVAudioPlayer?
    private var current: Int?
    private var timer: Timer?

    private let table = UITableView(frame: .zero, style: .plain)
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let slider = UISlider()
    private let playBtn = GlossyButton(title: "▶")
    private let spinner = UIActivityIndicatorView(style: .medium)

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Skin.linen()
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        buildUI()
        setupRemote()
    }

    // MARK: UI
    private func buildUI() {
        let topBar = GradientView(top: Skin.barTop, bottom: Skin.barBottom)
        let panel = GradientView(top: Skin.panelTop, bottom: Skin.panelBottom)
        let barTitle = UILabel()
        barTitle.text = "Music"
        barTitle.font = .boldSystemFont(ofSize: 20)
        barTitle.textColor = .white
        Skin.emboss(barTitle)

        let addBtn = GlossyButton(title: "+")
        let keyBtn = GlossyButton(title: "Key")
        let prevBtn = GlossyButton(title: "◀◀")
        let nextBtn = GlossyButton(title: "▶▶")
        addBtn.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        keyBtn.addTarget(self, action: #selector(keyTapped), for: .touchUpInside)
        prevBtn.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        nextBtn.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        playBtn.addTarget(self, action: #selector(playTapped), for: .touchUpInside)

        titleLabel.font = .boldSystemFont(ofSize: 17)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.text = "Нет трека"
        Skin.emboss(titleLabel)
        artistLabel.font = .systemFont(ofSize: 13)
        artistLabel.textColor = UIColor(white: 0.7, alpha: 1)
        artistLabel.textAlignment = .center
        slider.minimumTrackTintColor = Skin.accent
        slider.addTarget(self, action: #selector(seek), for: .valueChanged)

        table.backgroundColor = .clear
        table.separatorColor = UIColor(white: 0, alpha: 0.5)
        table.dataSource = self
        table.delegate = self
        spinner.color = .white
        spinner.hidesWhenStopped = true

        let btnRow = UIStackView(arrangedSubviews: [prevBtn, playBtn, nextBtn])
        btnRow.axis = .horizontal
        btnRow.spacing = 14
        btnRow.distribution = .fillEqually

        [table, topBar, panel, barTitle, addBtn, keyBtn, titleLabel, artistLabel, slider, btnRow, spinner]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        view.addSubview(table)
        view.addSubview(topBar)
        view.addSubview(panel)
        topBar.addSubview(barTitle); topBar.addSubview(addBtn); topBar.addSubview(keyBtn); topBar.addSubview(spinner)
        [titleLabel, artistLabel, slider, btnRow].forEach { panel.addSubview($0) }

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.bottomAnchor.constraint(equalTo: safe.topAnchor, constant: 44),

            barTitle.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            barTitle.centerYAnchor.constraint(equalTo: topBar.bottomAnchor, constant: -22),
            keyBtn.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 8),
            keyBtn.centerYAnchor.constraint(equalTo: barTitle.centerYAnchor),
            keyBtn.widthAnchor.constraint(equalToConstant: 52), keyBtn.heightAnchor.constraint(equalToConstant: 30),
            addBtn.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -8),
            addBtn.centerYAnchor.constraint(equalTo: barTitle.centerYAnchor),
            addBtn.widthAnchor.constraint(equalToConstant: 44), addBtn.heightAnchor.constraint(equalToConstant: 30),
            spinner.trailingAnchor.constraint(equalTo: addBtn.leadingAnchor, constant: -10),
            spinner.centerYAnchor.constraint(equalTo: barTitle.centerYAnchor),

            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            panel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            panel.topAnchor.constraint(equalTo: safe.bottomAnchor, constant: -150),

            titleLabel.topAnchor.constraint(equalTo: panel.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            slider.topAnchor.constraint(equalTo: artistLabel.bottomAnchor, constant: 10),
            slider.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 20),
            slider.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -20),
            btnRow.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 14),
            btnRow.centerXAnchor.constraint(equalTo: panel.centerXAnchor),
            btnRow.widthAnchor.constraint(equalToConstant: 240),
            btnRow.heightAnchor.constraint(equalToConstant: 42),

            table.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: panel.topAnchor),
        ])
    }

    // MARK: Добавление трека
    @objc private func addTapped() {
        let a = UIAlertController(title: "Добавить трек", message: "Ссылка SoundCloud или прямая ссылка на mp3/m4a", preferredStyle: .alert)
        a.addTextField { tf in
            tf.placeholder = "https://soundcloud.com/..."
            tf.keyboardType = .URL
            tf.autocapitalizationType = .none
            if let p = UIPasteboard.general.string, p.hasPrefix("http") { tf.text = p }
        }
        a.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        a.addAction(UIAlertAction(title: "Скачать", style: .default) { [weak self, weak a] _ in
            self?.importLink(a?.textFields?.first?.text ?? "")
        })
        present(a, animated: true)
    }

    @MainActor private func importLink(_ link: String) {
        spinner.startAnimating()
        Task {
            do {
                let r = try await TrackImporter.resolve(link: link)
                let t = try await TrackImporter.download(r)
                lib.add(t)
                table.reloadData()
            } catch {
                showError(error.localizedDescription)
            }
            spinner.stopAnimating()
        }
    }

    @objc private func keyTapped() {
        let a = UIAlertController(title: "SoundCloud client_id", message: "Твой ключ из личного приложения SoundCloud", preferredStyle: .alert)
        a.addTextField { $0.text = UserDefaults.standard.string(forKey: "sc_client_id"); $0.autocapitalizationType = .none }
        a.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        a.addAction(UIAlertAction(title: "Сохранить", style: .default) { [weak a] _ in
            UserDefaults.standard.set(a?.textFields?.first?.text ?? "", forKey: "sc_client_id")
        })
        present(a, animated: true)
    }

    private func showError(_ m: String) {
        let a = UIAlertController(title: "Ошибка", message: m, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    // MARK: Воспроизведение
    private func play(_ i: Int) {
        guard lib.tracks.indices.contains(i) else { return }
        let t = lib.tracks[i]
        do {
            player = try AVAudioPlayer(contentsOf: lib.url(for: t))
        } catch { showError("Не удалось открыть файл"); return }
        player?.delegate = self
        player?.play()
        current = i
        titleLabel.text = t.title
        artistLabel.text = t.artist
        playBtn.setTitle("❚❚", for: .normal)
        table.reloadData()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let p = self?.player, p.duration > 0 else { return }
            self?.slider.value = Float(p.currentTime / p.duration)
        }
        updateNowPlaying()
    }

    @objc private func playTapped() {
        guard let p = player else { if !lib.tracks.isEmpty { play(0) }; return }
        if p.isPlaying { p.pause(); playBtn.setTitle("▶", for: .normal) }
        else { p.play(); playBtn.setTitle("❚❚", for: .normal) }
        updateNowPlaying()
    }
    @objc private func nextTapped() {
        guard let c = current, !lib.tracks.isEmpty else { return }
        play((c + 1) % lib.tracks.count)
    }
    @objc private func prevTapped() {
        guard let c = current, !lib.tracks.isEmpty else { return }
        play((c - 1 + lib.tracks.count) % lib.tracks.count)
    }
    @objc private func seek() {
        guard let p = player else { return }
        p.currentTime = Double(slider.value) * p.duration
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { nextTapped() }

    // MARK: Экран блокировки
    private func setupRemote() {
        let c = MPRemoteCommandCenter.shared()
        c.playCommand.addTarget { [weak self] _ in self?.playTapped(); return .success }
        c.pauseCommand.addTarget { [weak self] _ in self?.playTapped(); return .success }
        c.nextTrackCommand.addTarget { [weak self] _ in self?.nextTapped(); return .success }
        c.previousTrackCommand.addTarget { [weak self] _ in self?.prevTapped(); return .success }
    }
    private func updateNowPlaying() {
        guard let c = current, let p = player else { return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: lib.tracks[c].title,
            MPMediaItemPropertyArtist: lib.tracks[c].artist,
            MPMediaItemPropertyPlaybackDuration: p.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: p.currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: p.isPlaying ? 1.0 : 0.0,
        ]
    }

    // MARK: Таблица
    func tableView(_ tv: UITableView, numberOfRowsInSection s: Int) -> Int { lib.tracks.count }

    func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let t = lib.tracks[ip.row]
        let playing = ip.row == current
        cell.textLabel?.text = (playing ? "▶  " : "") + t.title
        cell.textLabel?.textColor = playing ? Skin.accent : .white
        cell.textLabel?.font = .boldSystemFont(ofSize: 16)
        cell.detailTextLabel?.text = t.artist
        cell.detailTextLabel?.textColor = UIColor(white: 0.65, alpha: 1)
        cell.backgroundColor = UIColor(white: ip.row % 2 == 0 ? 0.0 : 1.0, alpha: ip.row % 2 == 0 ? 0.35 : 0.06)
        cell.selectionStyle = .gray
        return cell
    }

    func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)
        play(ip.row)
    }

    func tableView(_ tv: UITableView, commit style: UITableViewCell.EditingStyle, forRowAt ip: IndexPath) {
        guard style == .delete else { return }
        if current == ip.row { player?.stop(); player = nil; current = nil; titleLabel.text = "Нет трека"; artistLabel.text = "" }
        else if let c = current, c > ip.row { current = c - 1 }
        lib.remove(at: ip.row)
        tv.reloadData()
    }
}
