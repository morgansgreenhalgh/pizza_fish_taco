import Phaser from 'phaser';
import { GAME_HEIGHT, GAME_WIDTH } from '../shared/constants';
import { GameEvents, type BossStatsPayload, type PlayerStatsPayload } from '../shared/events';

export class Hud {
  private readonly scene: Phaser.Scene;
  private readonly scoreText: Phaser.GameObjects.Text;
  private readonly livesText: Phaser.GameObjects.Text;
  private readonly healthBar: Phaser.GameObjects.Rectangle;
  private readonly specialBar: Phaser.GameObjects.Rectangle;
  private readonly bossBar: Phaser.GameObjects.Rectangle;
  private readonly bossFrame: Phaser.GameObjects.Rectangle;
  private readonly bossText: Phaser.GameObjects.Text;
  private readonly meterTicks: Phaser.GameObjects.Rectangle[] = [];

  constructor(scene: Phaser.Scene) {
    this.scene = scene;
    const hud = scene.add.container(0, 0).setScrollFactor(0).setDepth(1010);

    scene.add.rectangle(0, 0, GAME_WIDTH, 94, 0x110912, 0.86).setOrigin(0).setScrollFactor(0).setDepth(999);
    scene.add.rectangle(22, 18, 76, 76, 0x13070b, 1).setOrigin(0).setStrokeStyle(4, 0xf8e6c1).setScrollFactor(0).setDepth(1001);
    hud.add(scene.add.image(60, 56, 'player-portrait').setScrollFactor(0).setDepth(1002));

    scene.add.text(112, 12, 'PIZZA FISH TACO', {
      fontFamily: 'monospace',
      fontSize: '28px',
      color: '#ffffff',
      stroke: '#000000',
      strokeThickness: 6,
    }).setScrollFactor(0).setDepth(1001);

    scene.add.rectangle(112, 50, 326, 24, 0x22111b, 1).setOrigin(0, 0.5).setStrokeStyle(4, 0xfaf0d7).setScrollFactor(0).setDepth(1001);
    this.healthBar = scene.add.rectangle(116, 50, 318, 14, 0x67ef1c, 1).setOrigin(0, 0.5).setScrollFactor(0).setDepth(1002);
    for (let i = 1; i < 14; i += 1) {
      this.meterTicks.push(scene.add.rectangle(116 + i * 22.7, 50, 2, 16, 0x0c2f12, 0.55).setScrollFactor(0).setDepth(1003));
    }
    scene.add.rectangle(112, 78, 226, 15, 0x22111b, 1).setOrigin(0, 0.5).setStrokeStyle(3, 0xfaf0d7).setScrollFactor(0).setDepth(1001);
    this.specialBar = scene.add.rectangle(115, 78, 0, 8, 0x34c9ff, 1).setOrigin(0, 0.5).setScrollFactor(0).setDepth(1002);

    this.livesText = scene.add.text(456, 39, 'x3', {
      fontFamily: 'monospace',
      fontSize: '24px',
      color: '#ffffff',
      stroke: '#000000',
      strokeThickness: 5,
    }).setScrollFactor(0).setDepth(1001);

    this.scoreText = scene.add.text(22, 112, 'SCORE 000000\nLVL 1-1', {
      fontFamily: 'monospace',
      fontSize: '24px',
      color: '#ffe900',
      stroke: '#000000',
      strokeThickness: 5,
      lineSpacing: 6,
    }).setScrollFactor(0).setDepth(1001);

    this.bossFrame = scene.add.rectangle(GAME_WIDTH / 2, 116, 420, 24, 0x220914, 0.95).setStrokeStyle(4, 0xffd347).setScrollFactor(0).setDepth(1001).setVisible(false);
    this.bossBar = scene.add.rectangle(GAME_WIDTH / 2 - 206, 116, 0, 14, 0xff3847, 1).setOrigin(0, 0.5).setScrollFactor(0).setDepth(1002).setVisible(false);
    this.bossText = scene.add.text(GAME_WIDTH / 2, 88, '', {
      fontFamily: 'monospace',
      fontSize: '20px',
      color: '#ffffff',
      stroke: '#000000',
      strokeThickness: 5,
    }).setOrigin(0.5).setScrollFactor(0).setDepth(1002).setVisible(false);

    this.createMiniMap(scene, hud);
    this.createAbilityBar(scene, hud);

    hud.add([this.healthBar, this.specialBar, ...this.meterTicks, this.livesText, this.scoreText, this.bossFrame, this.bossBar, this.bossText]);
    scene.events.on(GameEvents.playerStatsChanged, this.updatePlayer, this);
    scene.events.on(GameEvents.scoreChanged, this.updateScore, this);
    scene.events.on(GameEvents.bossStatsChanged, this.updateBoss, this);
  }

  destroy(): void {
    this.scene.events.off(GameEvents.playerStatsChanged, this.updatePlayer, this);
    this.scene.events.off(GameEvents.scoreChanged, this.updateScore, this);
    this.scene.events.off(GameEvents.bossStatsChanged, this.updateBoss, this);
  }

  private updatePlayer(stats: PlayerStatsPayload): void {
    this.healthBar.width = 318 * (stats.health / stats.maxHealth);
    this.specialBar.width = 220 * (stats.special / stats.maxSpecial);
    this.livesText.setText(`x${stats.lives}`);
  }

  private updateScore(score: number): void {
    this.scoreText.setText(`SCORE ${score.toString().padStart(6, '0')}\nLVL 1-1`);
  }

  private updateBoss(stats: BossStatsPayload): void {
    this.bossFrame.setVisible(stats.active);
    this.bossBar.setVisible(stats.active);
    this.bossText.setVisible(stats.active);
    this.bossText.setText(stats.name.toUpperCase());
    this.bossBar.width = 412 * (stats.health / stats.maxHealth);
  }

  private createMiniMap(scene: Phaser.Scene, hud: Phaser.GameObjects.Container): void {
    const frame = scene.add.rectangle(GAME_WIDTH - 118, 18, 156, 72, 0x12070c, 0.92).setOrigin(0).setStrokeStyle(3, 0x35f6ff).setScrollFactor(0).setDepth(1001);
    hud.add(frame);
    for (let i = 1; i < 5; i += 1) {
      hud.add(scene.add.rectangle(GAME_WIDTH - 118 + i * 31, 18, 1, 72, 0x0f7f86, 0.55).setOrigin(0).setScrollFactor(0).setDepth(1002));
    }
    for (let i = 1; i < 3; i += 1) {
      hud.add(scene.add.rectangle(GAME_WIDTH - 118, 18 + i * 24, 156, 1, 0x0f7f86, 0.55).setOrigin(0).setScrollFactor(0).setDepth(1002));
    }
    hud.add(scene.add.rectangle(GAME_WIDTH - 64, 52, 34, 30, 0x9e2c2b, 0.85).setScrollFactor(0).setDepth(1002));
    hud.add(scene.add.circle(GAME_WIDTH - 72, 54, 4, 0xffd447, 1).setScrollFactor(0).setDepth(1003));
  }

  private createAbilityBar(scene: Phaser.Scene, hud: Phaser.GameObjects.Container): void {
    const keys = ['ability-bite', 'ability-spin', 'ability-sauce', 'ability-jump'];
    const labels = ['BITE', 'SPIN', 'SAUCE', 'JUMP'];
    keys.forEach((key, index) => {
      const x = GAME_WIDTH / 2 - 117 + index * 78;
      hud.add(scene.add.image(x, GAME_HEIGHT - 48, key).setScrollFactor(0).setDepth(1001));
      hud.add(scene.add.text(x, GAME_HEIGHT - 15, labels[index], {
        fontFamily: 'monospace',
        fontSize: '15px',
        color: '#ffffff',
        stroke: '#000000',
        strokeThickness: 4,
      }).setOrigin(0.5).setScrollFactor(0).setDepth(1002));
    });
  }
}
