import type { Icon as PhosphorIcon } from "@phosphor-icons/react";
import {
  ArrowLeftIcon, ArrowsClockwiseIcon, BankIcon, CameraIcon, CaretDownIcon, CaretLeftIcon, CaretRightIcon, ChartBarIcon,
  ChatCircleIcon, CheckCircleIcon, CheckIcon, ClockIcon, CreditCardIcon, DiamondIcon, DownloadSimpleIcon, EnvelopeIcon,
  EyeIcon, EyeSlashIcon, FunnelIcon, GearIcon, GiftIcon, HandbagIcon, HeartIcon, HouseIcon, ImageIcon, ListIcon, LockIcon,
  MagnifyingGlassIcon, MapPinIcon, MinusIcon, MoneyIcon, PackageIcon, PencilSimpleIcon, PersonSimpleIcon, PhoneIcon,
  PlusIcon, PrinterIcon, ShareNetworkIcon, SignOutIcon, SparkleIcon, SquaresFourIcon, StorefrontIcon, TagIcon, TrashIcon,
  TruckIcon, UploadSimpleIcon, UserIcon, UsersThreeIcon, WarningIcon, XIcon,
} from "@phosphor-icons/react";

// One icon set (Phosphor) for the whole site, used through short names.
const icons = {
  dashboard: SquaresFourIcon, products: DiamondIcon, diamond: DiamondIcon, sparkle: SparkleIcon, orders: PackageIcon,
  bag: HandbagIcon, categories: SquaresFourIcon, customers: UsersThreeIcon, reports: ChartBarIcon, offers: TagIcon,
  settings: GearIcon, model: PersonSimpleIcon, logout: SignOutIcon, store: StorefrontIcon, home: HouseIcon, eye: EyeIcon,
  eyeOff: EyeSlashIcon, alert: WarningIcon, menu: ListIcon, user: UserIcon, heart: HeartIcon, search: MagnifyingGlassIcon,
  close: XIcon, check: CheckIcon, checkCircle: CheckCircleIcon, chevronLeft: CaretLeftIcon, chevronRight: CaretRightIcon,
  chevronDown: CaretDownIcon, arrowLeft: ArrowLeftIcon, plus: PlusIcon, minus: MinusIcon, trash: TrashIcon,
  edit: PencilSimpleIcon, upload: UploadSimpleIcon, camera: CameraIcon, image: ImageIcon, share: ShareNetworkIcon,
  download: DownloadSimpleIcon, filter: FunnelIcon, truck: TruckIcon, cash: MoneyIcon, bank: BankIcon, card: CreditCardIcon,
  chat: ChatCircleIcon, phone: PhoneIcon, mail: EnvelopeIcon, pin: MapPinIcon, clock: ClockIcon, print: PrinterIcon,
  refresh: ArrowsClockwiseIcon, lock: LockIcon, gift: GiftIcon,
} satisfies Record<string, PhosphorIcon>;

export type IconName = keyof typeof icons;

export default function Icon({ name, size = 20, filled = false }: { name: IconName; size?: number; filled?: boolean }) {
  const C = icons[name];
  return <C size={size} weight={filled ? "fill" : "regular"} aria-hidden="true" focusable="false" />;
}
