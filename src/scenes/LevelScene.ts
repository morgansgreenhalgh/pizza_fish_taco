import Phaser from 'phaser';
import { AttackHitbox } from '../entities/AttackHitbox';
import { Enemy, type EnemyKind } from '../entities/Enemy';
import { Player } from '../entities/Player';
import { ControllerInput } from '../input/ControllerInput';
import { GAME_HEIGHT, GAME_WIDTH, GROUND_Y, LEVEL_NAME, WORLD_WIDTH } from '../shared/constants';
import { GameEvents } from '../shared/events';
import { Hud } from '../ui/Hud';

type WaveConfig = {
  triggerX: number;
  enemies: Array<{ kind: EnemyKind; x: number }>;
  spawned?: boolean;
};

export class LevelScene extends Phaser.Scene {
  private player!: Player;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private enemies!: Phaser.Physics.Arcade.Group;
  private playerHitboxes!: Phaser.Physics.Arcade.Group;
  private controller!: ControllerInput;
  private hud?: Hud;
  private boss?: Enemy;
  private bossSpawned = false;
  private readonly waves: WaveConfig[] = [
    { triggerX: 260, enemies: [{ kind: 'burger-grunt', x: 640 }, { kind: 'burger-grunt', x: 770 }] },
    { triggerX: 880, enemies: [{ kind: 'burger-grunt', x: 1180 }, { kind: 'fry-goblin', x: 1280 }] },
    { triggerX: 1540, enemies: [{ kind: 'fry-goblin', x: 1780 }, { kind: 'burger-grunt', x: 1880 }, { kind: 'burger-grunt', x: 1990 }] },
  ];

  constructor() {
    super('LevelScene');
  }

  create(): void {
    this.physics.world.setBounds(0, 0, WORLD_WIDTH, GAME_HEIGHT);
    this.cameras.main.setBounds(0, 0, WORLD_WIDTH, GAME_HEIGHT);
    this.cursors = this.input.keyboard!.createCursorKeys();
    this.controller = new ControllerInput(this);
    this.createBackground();

    const ground = this.add.rectangle(WORLD_WIDTH / 2, GROUND_Y + 42, WORLD_WIDTH, 86, 0x7b3422).setStrokeStyle(4, 0xefac4f);
    this.physics.add.existing(ground, true);

    this.player = new Player(this, 130, GROUND_Y - 70);
    this.cameras.main.startFollow(this.player, true, 0.08, 0.08, -120, 80);

    this.enemies = this.physics.add.group({ runChildUpdate: false });
    this.playerHitboxes = this.physics.add.group({ runChildUpdate: false });
    this.hud = new Hud(this);
    this.player.emitStats();
    this.events.emit(GameEvents.scoreChanged, this.player.score);

    this.physics.add.collider(this.player, ground);
    this.physics.add.collider(this.enemies, ground);
    this.physics.add.collider(this.enemies, this.enemies);
    this.physics.add.overlap(this.playerHitboxes, this.enemies, this.handlePlayerHit, undefined, this);
    this.physics.add.overlap(this.player, this.enemies, this.handleEnemyTouch, undefined, this);

    this.events.on(GameEvents.playerDied, this.handlePlayerDied, this);
  }

  update(): void {
    const hitbox = this.player.update(this.cursors, this.controller.read());
    if (hitbox) {
      this.playerHitboxes.add(hitbox);
    }

    this.spawnWaves();
    this.spawnBossIfReady();
    this.enemies.children.each((child) => {
      const enemy = child as Enemy;
      if (!enemy.active) {
        return true;
      }

      const attacked = enemy.updateAi(this.player);
      if (attacked && Phaser.Math.Distance.Between(enemy.x, enemy.y, this.player.x, this.player.y) < (enemy.isBoss ? 132 : 74)) {
        this.player.receiveDamage(enemy.damage, enemy.isBoss ? 520 : 330, enemy.isBoss ? 260 : 180, enemy.x);
      }
      return true;
    });

    if (this.boss?.active) {
      this.events.emit(GameEvents.bossStatsChanged, {
        name: this.boss.displayName,
        health: this.boss.health,
        maxHealth: this.boss.maxHealth,
        active: true,
      });
    }
  }

  private createBackground(): void {
    this.add.rectangle(0, 0, WORLD_WIDTH, GAME_HEIGHT, 0x180716).setOrigin(0).setScrollFactor(0.2);
    this.add.rectangle(0, 88, WORLD_WIDTH, 180, 0x4b1029, 0.72).setOrigin(0).setScrollFactor(0.25);

    for (let i = 0; i < 18; i += 1) {
      const x = i * 190 + 40;
      this.add.circle(x, 210 + (i % 4) * 18, 62, 0x9a1d20, 0.22).setScrollFactor(0.28);
      this.add.circle(x + 44, 238, 18, 0xff6427, 0.35).setScrollFactor(0.28);
    }

    for (let i = 0; i < 11; i += 1) {
      const x = i * 330 + 70;
      this.add.rectangle(x, 296, 172, 278, 0x2c1020).setOrigin(0.5, 1).setScrollFactor(0.45);
      this.add.rectangle(x, 148, 132, 18, 0xe94124, 0.6).setScrollFactor(0.45);
      this.add.rectangle(x - 42, 212, 24, 82, 0x0f060d, 0.7).setScrollFactor(0.45);
      this.add.rectangle(x, 212, 24, 82, 0x0f060d, 0.7).setScrollFactor(0.45);
      this.add.rectangle(x + 42, 212, 24, 82, 0x0f060d, 0.7).setScrollFactor(0.45);
      this.add.circle(x + 58, 184, 12, 0xffd348, 0.55).setScrollFactor(0.45);
    }

    for (let i = 0; i < 9; i += 1) {
      const x = i * 390 + 120;
      this.add.rectangle(x, GROUND_Y - 120, 150, 74, 0x6b331c, 1).setStrokeStyle(5, 0x1b0908).setScrollFactor(0.78);
      this.add.text(x, GROUND_Y - 122, i % 2 === 0 ? 'HOT SAUCE' : 'EXTRA CHEESE', {
        fontFamily: 'monospace',
        fontSize: '16px',
        align: 'center',
        color: '#ff9f39',
        stroke: '#210706',
        strokeThickness: 4,
      }).setOrigin(0.5).setScrollFactor(0.78);
    }

    for (let i = 0; i < 19; i += 1) {
      const x = i * 180 + 50;
      this.add.circle(x, 382 + (i % 3) * 12, 44, 0x7d221a, 0.72).setScrollFactor(0.85);
      this.add.rectangle(x - 38, GROUND_Y - 20, 126, 48, 0xb54b25).setStrokeStyle(2, 0x33100b).setScrollFactor(1);
      this.add.rectangle(x - 38, GROUND_Y - 48, 126, 10, 0xffc44d).setScrollFactor(1);
      this.add.circle(x - 74, GROUND_Y - 23, 7, 0xffe071, 0.9).setScrollFactor(1);
      this.add.circle(x + 12, GROUND_Y - 18, 6, 0xef3322, 0.9).setScrollFactor(1);
    }

    this.add.rectangle(WORLD_WIDTH / 2, GROUND_Y + 2, WORLD_WIDTH, 10, 0xffcf55).setStrokeStyle(2, 0x1b0908);
    this.add.text(220, 340, 'SNACK CITY STREETS', {
      fontFamily: 'monospace',
      fontSize: '24px',
      color: '#ffe964',
      stroke: '#000000',
      strokeThickness: 5,
    });
  }

  private spawnWaves(): void {
    for (const wave of this.waves) {
      if (!wave.spawned && this.player.x >= wave.triggerX) {
        wave.spawned = true;
        wave.enemies.forEach((enemy) => this.spawnEnemy(enemy.kind, enemy.x));
      }
    }
  }

  private spawnBossIfReady(): void {
    if (this.bossSpawned || this.player.x < WORLD_WIDTH - 760) {
      return;
    }
    this.bossSpawned = true;
    this.boss = this.spawnEnemy('big-bad-burger', WORLD_WIDTH - 340);
    this.events.emit(GameEvents.bossSpawned);
  }

  private spawnEnemy(kind: EnemyKind, x: number): Enemy {
    const enemy = new Enemy(this, x, GROUND_Y - (kind === 'big-bad-burger' ? 102 : 58), kind);
    this.enemies.add(enemy);
    return enemy;
  }

  private handlePlayerHit(
    hitboxObject: Phaser.Types.Physics.Arcade.GameObjectWithBody | Phaser.Physics.Arcade.Body | Phaser.Physics.Arcade.StaticBody | Phaser.Tilemaps.Tile,
    enemyObject: Phaser.Types.Physics.Arcade.GameObjectWithBody | Phaser.Physics.Arcade.Body | Phaser.Physics.Arcade.StaticBody | Phaser.Tilemaps.Tile,
  ): void {
    const hitbox = hitboxObject as AttackHitbox;
    const enemy = enemyObject as Enemy;
    if (!hitbox.canHit(enemy) || enemy.isDead) {
      return;
    }

    hitbox.markHit(enemy);
    const hit = enemy.receiveDamage(hitbox.attack.damage, hitbox.attack.knockbackX, hitbox.attack.knockbackY, this.player.x);
    if (!hit) {
      return;
    }

    this.spawnHitSpark(enemy.x, enemy.y - 20);
    this.cameras.main.shake(hitbox.attack.kind === 'special' ? 130 : 70, hitbox.attack.kind === 'heavy' ? 0.006 : 0.003);

    if (enemy.isDead) {
      this.player.addScore(enemy.scoreValue);
      if (enemy.isBoss) {
        this.events.emit(GameEvents.bossStatsChanged, {
          name: enemy.displayName,
          health: 0,
          maxHealth: enemy.maxHealth,
          active: false,
        });
        this.time.delayedCall(900, () => this.scene.start('GameOverScene', { won: true, score: this.player.score }));
      }
    }
  }

  private handleEnemyTouch(
    _playerObject: Phaser.Types.Physics.Arcade.GameObjectWithBody | Phaser.Physics.Arcade.Body | Phaser.Physics.Arcade.StaticBody | Phaser.Tilemaps.Tile,
    enemyObject: Phaser.Types.Physics.Arcade.GameObjectWithBody | Phaser.Physics.Arcade.Body | Phaser.Physics.Arcade.StaticBody | Phaser.Tilemaps.Tile,
  ): void {
    const enemy = enemyObject as Enemy;
    if (enemy.isDead || this.player.isDead || this.time.now < enemy.attackCooldownUntil - 220) {
      return;
    }
    this.player.receiveDamage(Math.max(4, Math.floor(enemy.damage / 2)), 220, 130, enemy.x);
  }

  private handlePlayerDied(): void {
    if (this.player.lives <= 0) {
      this.time.delayedCall(1100, () => this.scene.start('GameOverScene', { won: false, score: this.player.score }));
    }
  }

  private spawnHitSpark(x: number, y: number): void {
    const spark = this.add.star(x, y, 7, 6, 22, 0xfff06b).setDepth(40);
    this.tweens.add({
      targets: spark,
      scale: 1.8,
      alpha: 0,
      duration: 180,
      onComplete: () => spark.destroy(),
    });
  }
}
