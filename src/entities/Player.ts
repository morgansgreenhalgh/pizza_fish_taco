import Phaser from 'phaser';
import { playerAttacks } from '../combat/attacks';
import { AttackHitbox } from './AttackHitbox';
import { GameEvents } from '../shared/events';
import type { ControllerSnapshot } from '../input/ControllerInput';
import type { AttackConfig } from '../shared/types';

type PlayerKeys = {
  left: Phaser.Input.Keyboard.Key;
  right: Phaser.Input.Keyboard.Key;
  up: Phaser.Input.Keyboard.Key;
  down: Phaser.Input.Keyboard.Key;
  jump: Phaser.Input.Keyboard.Key;
  light: Phaser.Input.Keyboard.Key;
  heavy: Phaser.Input.Keyboard.Key;
  special: Phaser.Input.Keyboard.Key;
};

export class Player extends Phaser.Physics.Arcade.Sprite {
  declare readonly body: Phaser.Physics.Arcade.Body;
  health = 120;
  maxHealth = 120;
  lives = 3;
  special = 50;
  maxSpecial = 100;
  score = 0;
  facing: -1 | 1 = 1;
  isDead = false;
  isAttacking = false;
  isHurt = false;
  private comboStep = 0;
  private comboResetAt = 0;
  private attackLockedUntil = 0;
  private invulnerableUntil = 0;
  private readonly keys: PlayerKeys;
  private readonly speed = 280;
  private readonly jumpSpeed = 690;

  constructor(scene: Phaser.Scene, x: number, y: number) {
    super(scene, x, y, 'pizza-fish-taco');
    scene.add.existing(this);
    scene.physics.add.existing(this);
    this.setCollideWorldBounds(true);
    this.setDepth(12);
    this.body.setSize(72, 82);
    this.body.setOffset(28, 20);

    const keyboard = scene.input.keyboard;
    if (!keyboard) {
      throw new Error('Keyboard input is required for the Phase 1 MVP.');
    }

    this.keys = {
      left: keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.A),
      right: keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.D),
      up: keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.W),
      down: keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.S),
      jump: keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE),
      light: keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.J),
      heavy: keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.K),
      special: keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.L),
    };
    keyboard.createCursorKeys();
    this.emitStats();
  }

  update(cursors: Phaser.Types.Input.Keyboard.CursorKeys, controller: ControllerSnapshot): AttackHitbox | undefined {
    if (this.isDead) {
      return undefined;
    }

    const now = this.scene.time.now;
    const onFloor = this.body.blocked.down || this.body.touching.down;
    if (now > this.comboResetAt) {
      this.comboStep = 0;
    }

    const keyboardHorizontal = Number(cursors.right?.isDown || this.keys.right.isDown) - Number(cursors.left?.isDown || this.keys.left.isDown);
    const horizontal = keyboardHorizontal !== 0 ? keyboardHorizontal : controller.horizontal;
    if (!this.isAttacking && !this.isHurt) {
      this.setVelocityX(horizontal * this.speed);
      if (horizontal !== 0) {
        this.facing = horizontal > 0 ? 1 : -1;
        this.setFlipX(this.facing < 0);
      }
    } else if (onFloor) {
      this.setVelocityX(this.body.velocity.x * 0.82);
    }

    if ((Phaser.Input.Keyboard.JustDown(cursors.space!) || Phaser.Input.Keyboard.JustDown(this.keys.jump) || Phaser.Input.Keyboard.JustDown(this.keys.up) || controller.jumpPressed) && onFloor) {
      this.setVelocityY(-this.jumpSpeed);
    }

    if (now < this.attackLockedUntil || this.isHurt) {
      return undefined;
    }

    if (Phaser.Input.Keyboard.JustDown(this.keys.light) || controller.lightPressed) {
      this.comboStep = (this.comboStep % 3) + 1;
      this.comboResetAt = now + 620;
      return this.startAttack(playerAttacks[`light${this.comboStep}` as 'light1' | 'light2' | 'light3']);
    }

    if (Phaser.Input.Keyboard.JustDown(this.keys.heavy) || controller.heavyPressed) {
      this.comboStep = 0;
      return this.startAttack(playerAttacks.heavy);
    }

    if ((Phaser.Input.Keyboard.JustDown(this.keys.special) || controller.specialPressed) && this.special >= (playerAttacks.special.specialCost ?? 0)) {
      this.comboStep = 0;
      this.special -= playerAttacks.special.specialCost ?? 0;
      this.scene.events.emit(GameEvents.playerStatsChanged, this.statsPayload());
      return this.startAttack(playerAttacks.special);
    }

    return undefined;
  }

  receiveDamage(amount: number, knockbackX: number, knockbackY: number, sourceX: number): void {
    if (this.isDead || this.scene.time.now < this.invulnerableUntil) {
      return;
    }

    this.health = Math.max(0, this.health - amount);
    const direction = this.x >= sourceX ? 1 : -1;
    this.setVelocity(direction * knockbackX, -knockbackY);
    this.setTintFill(0xfff4d0);
    this.isHurt = true;
    this.invulnerableUntil = this.scene.time.now + 820;
    this.scene.events.emit(GameEvents.playerStatsChanged, this.statsPayload());

    this.scene.time.delayedCall(120, () => this.clearTint());
    this.scene.time.delayedCall(320, () => {
      this.isHurt = false;
    });

    if (this.health <= 0) {
      this.loseLife();
    }
  }

  addScore(amount: number): void {
    this.score += amount;
    this.special = Math.min(this.maxSpecial, this.special + 12);
    this.scene.events.emit(GameEvents.scoreChanged, this.score);
    this.emitStats();
  }

  emitStats(): void {
    this.scene.events.emit(GameEvents.playerStatsChanged, this.statsPayload());
  }

  private startAttack(attack: AttackConfig): AttackHitbox {
    this.isAttacking = true;
    this.attackLockedUntil = this.scene.time.now + attack.duration + attack.recovery;
    this.setVelocityX(this.body.velocity.x * 0.25);
    this.setTint(attack.kind === 'special' ? 0x44e7ff : attack.kind === 'heavy' ? 0xff9f2e : 0xffffff);
    this.scene.time.delayedCall(attack.duration, () => {
      this.clearTint();
    });
    this.scene.time.delayedCall(attack.duration + attack.recovery, () => {
      this.isAttacking = false;
    });
    return new AttackHitbox(this.scene, this, this.x, this.y + 2, this.facing, attack);
  }

  private loseLife(): void {
    this.lives -= 1;
    this.isDead = true;
    this.setTint(0x5c2734);
    this.setVelocity(0, -420);
    this.scene.events.emit(GameEvents.playerStatsChanged, this.statsPayload());
    this.scene.events.emit(GameEvents.playerDied);

    if (this.lives > 0) {
      this.scene.time.delayedCall(1200, () => {
        this.health = this.maxHealth;
        this.special = Math.max(40, this.special);
        this.isDead = false;
        this.isHurt = false;
        this.clearTint();
        this.enableBody(true, Math.max(120, this.x - 180), 330, true, true);
        this.scene.events.emit(GameEvents.playerStatsChanged, this.statsPayload());
      });
    }
  }

  private statsPayload() {
    return {
      health: this.health,
      maxHealth: this.maxHealth,
      lives: this.lives,
      special: this.special,
      maxSpecial: this.maxSpecial,
    };
  }
}
